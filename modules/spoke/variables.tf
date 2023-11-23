#############
# Global:
#############

variable "region" {
  description = "The Region"
  default     = "il-central-1"

  validation {
    condition     = can(regex("[a-z][a-z]-[a-z]+-[1-9]", var.region))
    error_message = "Must be valid AWS Region names."
  }
}

variable "number_azs" {
  description = "The number of Availability Zones (AZs) for the Hub"
}

variable "create_trail" {
  description = "Whether to create a local CloudTrail"
  default = false
  type = bool
}

#########################
# Network:
#########################

variable "spoke_vpc_cidr_block" {
  description = "The VPC CIDR block for Spoke VPC"

  validation {
    condition     = can(cidrhost(var.spoke_vpc_cidr_block, 0)) && can(regex("/22", var.spoke_vpc_cidr_block))
    error_message = "Must be valid IPv4 CIDR on the format: 10.x.x.x/22"
  }
}

#########################
# Subnets CIDR Blocks:
#########################

locals {
  spoke_subnets_cidr_blocks = {
    tgw   = [for i in range(0, var.number_azs) : cidrsubnet(var.spoke_vpc_cidr_block, 6, i)]
    spoke = [for i in range(1, var.number_azs + 1) : cidrsubnet(var.spoke_vpc_cidr_block, 2, i)]
  }
}
