
############################
### Firewall
############################

# Firewall Rule Group
resource "aws_networkfirewall_rule_group" "egress-rule-group" {
  capacity = 100
  name     = "egress-rule-group"
  type     = "STATEFUL"
  rule_group {
    rules_source {
      stateful_rule {
        action = "PASS"
        header {
          destination      = "ANY"
          destination_port = "ANY"
          direction        = "ANY"
          protocol         = "ICMP"
          source           = "ANY"
          source_port      = "ANY"
        }
        rule_option {
          keyword  = "sid"
          settings = ["1"]
        }
      }
    }

    stateful_rule_options {
      rule_order = "STRICT_ORDER"
    }
  }

  tags = {
    Name = "egress-rule-group"
  }
}

# Firewall policy
resource "aws_networkfirewall_firewall_policy" "hub_firewall_policy" {
  name = "hub-firewall-policy"

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]

    stateful_rule_group_reference {
      priority     = 65000
      resource_arn = aws_networkfirewall_rule_group.egress-rule-group.arn
    }

    stateful_engine_options {
      rule_order = "STRICT_ORDER"
    }

    stateful_default_actions = ["aws:drop_strict"]
  }

  tags = {
    Name = "hub-firewall-policy"
  }
}

# Firewall Configuration
resource "aws_networkfirewall_firewall" "hub_firewall" {
  name                = "hub-inspection-firewall"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.hub_firewall_policy.arn
  vpc_id              = aws_vpc.inspection_vpc.id

  dynamic "subnet_mapping" {
    for_each = aws_subnet.inspection_firewall_subnets[*].id

    content {
      subnet_id = subnet_mapping.value
    }
  }

  tags = {
    Name = "hub-inspection-firewall"
  }
}

# Firewall Loggings
resource "aws_cloudwatch_log_group" "firewall_flow_log_group" {
  name              = "/aws/networkfirewall/hub-inspection-firewall/flow"
  retention_in_days = 365
  skip_destroy      = false
}

resource "aws_cloudwatch_log_group" "firewall_alert_log_group" {
  name              = "/aws/networkfirewall/hub-inspection-firewall/alert"
  retention_in_days = 365
  skip_destroy      = false
}

resource "aws_networkfirewall_logging_configuration" "hub_firewall_log_config" {
  firewall_arn = aws_networkfirewall_firewall.hub_firewall.arn

  logging_configuration {
    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.firewall_flow_log_group.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "FLOW"
    }

    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.firewall_alert_log_group.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "ALERT"
    }
  }
}
