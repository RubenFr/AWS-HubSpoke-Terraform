############################
### Inspection VPC
############################

resource "aws_vpc" "inspection_vpc" {
  cidr_block           = var.inspection_vpc_cidr_block
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "hub-inspection-vpc"
  }
}

# TGW Subnets
resource "aws_subnet" "inspection_tgw_subnets" {
  count             = var.number_azs
  vpc_id            = aws_vpc.inspection_vpc.id
  cidr_block        = local.inspection_subnets_cidr_blocks.tgw[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "hub-inspection-tgw-subnet-${split("-", data.aws_availability_zones.available.names[count.index])[2]}"
  }
}

resource "aws_route_table" "inspection_tgw_rt" {
  count  = var.number_azs
  vpc_id = aws_vpc.inspection_vpc.id

  route {
    cidr_block      = "0.0.0.0/0"
    vpc_endpoint_id = element([for ss in tolist(aws_networkfirewall_firewall.hub_firewall.firewall_status[0].sync_states) : ss.attachment[0].endpoint_id if ss.attachment[0].subnet_id == aws_subnet.inspection_firewall_subnets[count.index].id], 0)
  }

  tags = {
    Name = "inspection-tgw-rt-${split("-", data.aws_availability_zones.available.names[count.index])[2]}"
  }
}

resource "aws_route_table_association" "inspection_tgw_rt_assoc" {
  count          = var.number_azs
  subnet_id      = aws_subnet.inspection_tgw_subnets[count.index].id
  route_table_id = aws_route_table.inspection_tgw_rt[count.index].id
}

# Firewall Subnets
resource "aws_subnet" "inspection_firewall_subnets" {
  count             = var.number_azs
  vpc_id            = aws_vpc.inspection_vpc.id
  cidr_block        = local.inspection_subnets_cidr_blocks.firewall[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "hub-inspection-firewall-subnet-${split("-", data.aws_availability_zones.available.names[count.index])[2]}"
  }
}

resource "aws_route_table" "inspection_firewall_rt" {
  vpc_id = aws_vpc.inspection_vpc.id

  route {
    cidr_block         = "0.0.0.0/0"
    transit_gateway_id = aws_ec2_transit_gateway.hub_tgw.id
  }

  tags = {
    Name = "inspection-firewall-rt"
  }
}

resource "aws_route_table_association" "inspection_firewall_rt_assoc" {
  count          = var.number_azs
  subnet_id      = aws_subnet.inspection_firewall_subnets[count.index].id
  route_table_id = aws_route_table.inspection_firewall_rt.id
}

# TGW Attachment
resource "aws_ec2_transit_gateway_vpc_attachment" "inspection_tgw_attach" {

  transit_gateway_id = aws_ec2_transit_gateway.hub_tgw.id
  vpc_id             = aws_vpc.inspection_vpc.id
  subnet_ids         = aws_subnet.inspection_tgw_subnets[*].id

  dns_support                                     = "enable"
  appliance_mode_support                          = "enable"
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name = "inspection-tgw-attach"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "inspection_tgw_attach_rt_assoc" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.inspection_tgw_attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.inspection_tgw_rt.id
}
