################
# VPCs
################

output "egress_vpc" {
  description = "Egress VPC"
  value = {
    id   = aws_vpc.egress_vpc.id
    url  = "https://${var.region}.console.aws.amazon.com/vpcconsole/home?#VpcDetails:VpcId=${aws_vpc.egress_vpc.id}"
    cidr = aws_vpc.egress_vpc.cidr_block
  }
}

output "ingress_vpc" {
  description = "Ingress VPC"
  value = {
    id                   = aws_vpc.ingress_vpc.id
    url                  = "https://${var.region}.console.aws.amazon.com/vpcconsole/home?#VpcDetails:VpcId=${aws_vpc.ingress_vpc.id}"
    cidr                 = aws_vpc.ingress_vpc.cidr_block
    clientvpn_subnet_ids = aws_subnet.ingress_clientvpn_subnets[*].id
  }
}

output "inspection_vpc" {
  description = "Inspection VPC"
  value = {
    id   = aws_vpc.inspection_vpc.id
    url  = "https://${var.region}.console.aws.amazon.com/vpcconsole/home?#VpcDetails:VpcId=${aws_vpc.inspection_vpc.id}"
    cidr = aws_vpc.inspection_vpc.cidr_block
  }
}

################
# TGW
################

output "hub_tgw_id" {
  description = "Mamram Hub Transit Gateway Id"
  value       = aws_ec2_transit_gateway.hub_tgw.id
}

################
# Firewall
################

output "hub_firewall_arn" {
  description = "Mamram Hub Inspection Firewall Arn"
  value       = aws_networkfirewall_firewall.hub_firewall.arn
}

output "hub_firewall_policy_arn" {
  description = "Mamram Hub Inspection Firewall Arn"
  value       = aws_networkfirewall_firewall_policy.hub_firewall_policy.arn
}
