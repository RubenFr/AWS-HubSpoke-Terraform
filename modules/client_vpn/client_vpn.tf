
############################
### Client VPN
############################

resource "aws_cloudwatch_log_group" "clientvpn_lg" {
  name              = "/aws/clientvpn"
  retention_in_days = 365
  skip_destroy      = false
}

resource "aws_cloudwatch_log_stream" "clientvpn_ls" {
  name           = "logs"
  log_group_name = aws_cloudwatch_log_group.clientvpn_lg.name
}

resource "aws_security_group" "clienvpn_security_group" {
  name        = "clientvpn-sg"
  description = "Security Group for Client VPN"
  vpc_id      = var.clientvpn_vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "clientvpn-sg"
  }
}

resource "aws_ec2_client_vpn_endpoint" "clientvpn_endpoint" {
  description = "TLV Hub Client VPN. Connected to Ingress VPC (${var.clientvpn_vpc_id})"

  # Networking
  vpc_id             = var.clientvpn_vpc_id
  security_group_ids = [aws_security_group.clienvpn_security_group.id]
  client_cidr_block  = var.clientvpn_cidr_block
  split_tunnel       = false
  transport_protocol = "tcp"
  vpn_port           = 443

  session_timeout_hours  = 10
  server_certificate_arn = data.aws_acm_certificate.client_vpn_cert.arn
  self_service_portal    = local.enable_self_service_portal ? "enabled" : "disabled"

  authentication_options {
    type                           = "federated-authentication"
    saml_provider_arn              = "arn:aws:iam::${local.account_id}:saml-provider/${var.clientvpn_idp_id}"
    self_service_saml_provider_arn = local.enable_self_service_portal ? "arn:aws:iam::${local.account_id}:saml-provider/${var.clientvpn_self_service_idp_id}" : null
  }

  connection_log_options {
    enabled               = true
    cloudwatch_log_group  = aws_cloudwatch_log_group.clientvpn_lg.name
    cloudwatch_log_stream = aws_cloudwatch_log_stream.clientvpn_ls.name
  }

  tags = {
    Name = "tlv-hub-clientvpn"
  }

}

resource "aws_ec2_client_vpn_network_association" "clientvpn_network_associations" {
  count = length(var.clientvpn_subnet_ids)

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.clientvpn_endpoint.id
  subnet_id              = var.clientvpn_subnet_ids[count.index]
}

resource "aws_ec2_client_vpn_route" "clientvpn_routes" {
  count = length(var.clientvpn_subnet_ids)

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.clientvpn_endpoint.id
  destination_cidr_block = "10.0.0.0/8"
  target_vpc_subnet_id   = var.clientvpn_subnet_ids[count.index]

  depends_on = [aws_ec2_client_vpn_network_association.clientvpn_network_associations]
}
