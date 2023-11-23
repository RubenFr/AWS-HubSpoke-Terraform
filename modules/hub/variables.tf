#############
# Global:
#############

variable "region" {
  description = "The Region"
}

variable "number_azs" {
  description = "The number of Availability Zones (AZs) for the Hub"
}

#########################
# VPC CIDR Blocks:
#########################

variable "egress_vpc_cidr_block" {
  description = "The VPC CIDR block for the Egress VPC"
}

variable "ingress_vpc_cidr_block" {
  description = "The VPC CIDR block for Ingress VPC Subnet"
}

variable "inspection_vpc_cidr_block" {
  description = "The VPC CIDR block for Inspection VPC Subnet"
}

#####################################
# Resource Access Manager (RAM):
#####################################

variable "ram_principals" {
  description = "The principals to share the Hub TGW with"
}

#########################
# Subnets CIDR Blocks:
#########################

locals {
  egress_subnets_cidr_blocks = {
    tgw    = [for i in range(0, var.number_azs) : cidrsubnet(var.egress_vpc_cidr_block, 12, i)]
    public = [for i in range(1, var.number_azs + 1) : cidrsubnet(var.egress_vpc_cidr_block, 8, i)]
  }
}

locals {
  ingress_subnets_cidr_blocks = {
    tgw       = [for i in range(0, var.number_azs) : cidrsubnet(var.ingress_vpc_cidr_block, 12, i)]
    public    = [for i in range(1, var.number_azs + 1) : cidrsubnet(var.ingress_vpc_cidr_block, 8, i)]
    private   = [for i in range(var.number_azs + 1, 2 * var.number_azs + 1) : cidrsubnet(var.ingress_vpc_cidr_block, 8, i)]
    clientvpn = [for i in range(2 * var.number_azs + 1, 3 * var.number_azs + 1) : cidrsubnet(var.ingress_vpc_cidr_block, 8, i)]
  }
}

locals {
  inspection_subnets_cidr_blocks = {
    tgw      = [for i in range(0, var.number_azs) : cidrsubnet(var.inspection_vpc_cidr_block, 12, i)]
    firewall = [for i in range(1, var.number_azs + 1) : cidrsubnet(var.inspection_vpc_cidr_block, 8, i)]
  }
}

