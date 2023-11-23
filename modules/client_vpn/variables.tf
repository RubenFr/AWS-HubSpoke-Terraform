#############
# Global:
#############

variable "region" {
  description = "The Region"
}

#########################
# Netork CIDR Blocks:
#########################

variable "clientvpn_vpc_id" {
  description = "The ID of the VPC you want to put the VPC in"
}

variable "clientvpn_subnet_ids" {
  description = "The ID of the Subnets you want to put the VPC in"
}

#####################
# Security
#####################

variable "clientvpn_domain" {
  description = "The domain under wich a certificate has been issued for the Client VPN"
  default     = "tlv-clientvpn.dev.idf.il"
}

variable "clientvpn_idp_id" {
  description = "The Identity Provider of the Client VPN"
}

variable "clientvpn_self_service_idp_id" {
  description = "The Identity Provider of the Self Service Client VPN"
  default     = null
  type        = string
}

locals {
  enable_self_service_portal = var.clientvpn_self_service_idp_id != null
}

variable "clientvpn_cidr_block" {
  description = "The CIDR block Client VPN"
  type        = string
  default     = "172.10.0.0/22"
}


