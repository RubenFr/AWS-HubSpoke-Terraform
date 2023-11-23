################
# VPCs
################

output "vpc" {
  description = "Spoke VPC"
  value = {
    id   = aws_vpc.spoke_vpc.id
    url  = "https://${var.region}.console.aws.amazon.com/vpcconsole/home?#VpcDetails:VpcId=${aws_vpc.spoke_vpc.id}"
    vpc_cidr = aws_vpc.spoke_vpc.cidr_block
    tgw_cidrs = local.spoke_subnets_cidr_blocks.tgw
    spoke_cidrs = local.spoke_subnets_cidr_blocks.spoke
  }
}

output "tgw_attachment" {
    value = aws_ec2_transit_gateway_vpc_attachment.tgw_attachment.id
}