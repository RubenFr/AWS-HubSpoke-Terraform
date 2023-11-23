############################
### TGW
############################

resource "aws_ec2_transit_gateway" "hub_tgw" {

  description                     = "Mamram Hub Transit Gateway (TGW)"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  auto_accept_shared_attachments  = "enable"
  dns_support                     = "enable"

  tags = {
    Name = "hub-tgw"
  }
}

# Spoke Route Table
resource "aws_ec2_transit_gateway_route_table" "spoke_tgw_rt" {
  transit_gateway_id = aws_ec2_transit_gateway.hub_tgw.id

  tags = {
    Name = "spoke-tgw-rt"
  }
}

resource "aws_ec2_transit_gateway_route" "spoke_tgw_rt_default_route" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.inspection_tgw_attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke_tgw_rt.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.inspection_tgw_attach]
}

# Inspection Route Table
resource "aws_ec2_transit_gateway_route_table" "inspection_tgw_rt" {
  transit_gateway_id = aws_ec2_transit_gateway.hub_tgw.id

  tags = {
    Name = "inspection-tgw-rt"
  }
}

resource "aws_ec2_transit_gateway_route" "inspection_tgw_rt_default_route" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.egress_tgw_attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.inspection_tgw_rt.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.egress_tgw_attach]
}


################################################################################
### Resource Access Manager
################################################################################

resource "aws_ram_resource_share" "tgw_share" {
  name                      = "hub-tgw-share"
  allow_external_principals = false

  tags = {
    Name = "hub-tgw-share"
  }
}

resource "aws_ram_resource_association" "tgw_share" {
  resource_arn       = aws_ec2_transit_gateway.hub_tgw.arn
  resource_share_arn = aws_ram_resource_share.tgw_share.id
}

resource "aws_ram_principal_association" "tgw_share" {
  count = length(var.ram_principals)

  principal          = var.ram_principals[count.index]
  resource_share_arn = aws_ram_resource_share.tgw_share.arn
}
