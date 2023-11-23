
############################
### Egress VPC
############################

resource "aws_vpc" "egress_vpc" {
  cidr_block           = var.egress_vpc_cidr_block
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "hub-egress-vpc"
  }
}

# TGW Subnets
resource "aws_subnet" "egress_tgw_subnets" {
  count             = var.number_azs
  vpc_id            = aws_vpc.egress_vpc.id
  cidr_block        = local.egress_subnets_cidr_blocks.tgw[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "hub-egress-tgw-subnet-${split("-", data.aws_availability_zones.available.names[count.index])[2]}"
  }
}

resource "aws_route_table" "egress_tgw_rt" {
  count  = var.number_azs
  vpc_id = aws_vpc.egress_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.egress-natgw[count.index].id
  }

  tags = {
    Name = "egress-tgw-rt-${split("-", data.aws_availability_zones.available.names[count.index])[2]}"
  }
}

resource "aws_route_table_association" "egress_tgw_rt_assoc" {
  count          = var.number_azs
  subnet_id      = aws_subnet.egress_tgw_subnets[count.index].id
  route_table_id = aws_route_table.egress_tgw_rt[count.index].id
}

# Public Subnets
resource "aws_subnet" "egress_public_subnets" {
  count             = var.number_azs
  vpc_id            = aws_vpc.egress_vpc.id
  cidr_block        = local.egress_subnets_cidr_blocks.public[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "hub-egress-public-subnet-${split("-", data.aws_availability_zones.available.names[count.index])[2]}"
  }
}

resource "aws_route_table" "egress_public_rt" {
  vpc_id = aws_vpc.egress_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.egress_igw.id
  }

  route {
    cidr_block         = "10.0.0.0/8"
    transit_gateway_id = aws_ec2_transit_gateway.hub_tgw.id
  }

  tags = {
    Name = "egress-public-rt"
  }
}

resource "aws_route_table_association" "egress_public_rt_assoc" {
  count          = var.number_azs
  subnet_id      = aws_subnet.egress_public_subnets[count.index].id
  route_table_id = aws_route_table.egress_public_rt.id
}

# TGW Attachment
resource "aws_ec2_transit_gateway_vpc_attachment" "egress_tgw_attach" {

  transit_gateway_id = aws_ec2_transit_gateway.hub_tgw.id
  vpc_id             = aws_vpc.egress_vpc.id
  subnet_ids         = aws_subnet.egress_tgw_subnets[*].id

  dns_support                                     = "enable"
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name = "egress-tgw-attach"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "egress_tgw_attach_rt_assoc" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.egress_tgw_attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke_tgw_rt.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "egress_tgw_attach_rt_propagation" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.egress_tgw_attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.inspection_tgw_rt.id
}

# IGW & NATs
resource "aws_internet_gateway" "egress_igw" {
  vpc_id = aws_vpc.egress_vpc.id

  tags = {
    Name = "egress-igw"
  }
}

resource "aws_eip" "egress-eip" {
  count = var.number_azs

  tags = {
    Name = "egress-nat-eip-${split("-", data.aws_availability_zones.available.names[count.index])[2]}"
  }
}

resource "aws_nat_gateway" "egress-natgw" {
  count = var.number_azs

  subnet_id     = aws_subnet.egress_public_subnets[count.index].id
  allocation_id = aws_eip.egress-eip[count.index].id

  tags = {
    Name = "egress-natgw-${split("-", data.aws_availability_zones.available.names[count.index])[2]}"
  }

  depends_on = [aws_internet_gateway.egress_igw]
}
