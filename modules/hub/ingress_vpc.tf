############################
### Ingress VPC
############################

resource "aws_vpc" "ingress_vpc" {
  cidr_block           = var.ingress_vpc_cidr_block
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "hub-ingress-vpc"
  }
}

# TGW Subnets
resource "aws_subnet" "ingress_tgw_subnets" {
  count             = var.number_azs
  vpc_id            = aws_vpc.ingress_vpc.id
  cidr_block        = local.ingress_subnets_cidr_blocks.tgw[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "hub-ingress-tgw-subnet-${split("-", data.aws_availability_zones.available.names[count.index])[2]}"
  }
}

resource "aws_route_table" "ingress_tgw_rt" {
  vpc_id = aws_vpc.ingress_vpc.id

  tags = {
    Name = "ingress-tgw-rt"
  }
}

resource "aws_route_table_association" "ingress_tgw_rt_assoc" {
  count          = var.number_azs
  subnet_id      = aws_subnet.ingress_tgw_subnets[count.index].id
  route_table_id = aws_route_table.ingress_tgw_rt.id
}

# Public Subnets
resource "aws_subnet" "ingress_public_subnets" {
  count             = var.number_azs
  vpc_id            = aws_vpc.ingress_vpc.id
  cidr_block        = local.ingress_subnets_cidr_blocks.public[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "hub-ingress-public-subnet-${split("-", data.aws_availability_zones.available.names[count.index])[2]}"
  }
}

resource "aws_route_table" "ingress_public_rt" {
  vpc_id = aws_vpc.ingress_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ingress_igw.id
  }

  route {
    cidr_block         = "10.0.0.0/8"
    transit_gateway_id = aws_ec2_transit_gateway.hub_tgw.id
  }

  tags = {
    Name = "ingress-public-rt"
  }
}

resource "aws_route_table_association" "ingress_public_rt_assoc" {
  count          = var.number_azs
  subnet_id      = aws_subnet.ingress_public_subnets[count.index].id
  route_table_id = aws_route_table.ingress_public_rt.id
}

# # Private Subnets
# resource "aws_subnet" "ingress_private_subnets" {
#   count             = var.number_azs
#   vpc_id            = aws_vpc.ingress_vpc.id
#   cidr_block        = local.ingress_subnets_cidr_blocks.private[count.index]
#   availability_zone = data.aws_availability_zones.available.names[count.index]

#   tags = {
#     Name = "hub-ingress-private-subnet-${split("-", data.aws_availability_zones.available.names[count.index])[2]}"
#   }
# }

# resource "aws_route_table" "ingress_private_rt" {
#   vpc_id = aws_vpc.ingress_vpc.id

#   route {
#     cidr_block         = "10.0.0.0/8"
#     transit_gateway_id = aws_ec2_transit_gateway.hub_tgw.id
#   }

#   tags = {
#     Name = "ingress-private-rt"
#   }
# }

# resource "aws_route_table_association" "ingress_private_rt_assoc" {
#   count          = var.number_azs
#   subnet_id      = aws_subnet.ingress_private_subnets[count.index].id
#   route_table_id = aws_route_table.ingress_private_rt.id
# }

# Client VPN Subnets
resource "aws_subnet" "ingress_clientvpn_subnets" {
  count             = var.number_azs
  vpc_id            = aws_vpc.ingress_vpc.id
  cidr_block        = local.ingress_subnets_cidr_blocks.clientvpn[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "hub-ingress-clientvpn-subnet-${split("-", data.aws_availability_zones.available.names[count.index])[2]}"
  }
}

resource "aws_route_table" "ingress_clientvpn_rt" {
  vpc_id = aws_vpc.ingress_vpc.id

  route {
    cidr_block         = "10.0.0.0/8"
    transit_gateway_id = aws_ec2_transit_gateway.hub_tgw.id
  }

  tags = {
    Name = "ingress-clientvpn-rt"
  }
}

resource "aws_route_table_association" "ingress_clientvpn_rt_assoc" {
  count          = var.number_azs
  subnet_id      = aws_subnet.ingress_clientvpn_subnets[count.index].id
  route_table_id = aws_route_table.ingress_clientvpn_rt.id
}

# TGW Attachment
resource "aws_ec2_transit_gateway_vpc_attachment" "ingress_tgw_attach" {

  transit_gateway_id = aws_ec2_transit_gateway.hub_tgw.id
  vpc_id             = aws_vpc.ingress_vpc.id
  subnet_ids         = aws_subnet.ingress_tgw_subnets[*].id

  dns_support                                     = "enable"
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name = "ingress-tgw-attach"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "ingress_tgw_attach_rt_assoc" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.ingress_tgw_attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke_tgw_rt.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "ingress_tgw_attach_rt_propagation" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.ingress_tgw_attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.inspection_tgw_rt.id
}

# IGW & NATs
resource "aws_internet_gateway" "ingress_igw" {
  vpc_id = aws_vpc.ingress_vpc.id

  tags = {
    Name = "ingress-igw"
  }
}
