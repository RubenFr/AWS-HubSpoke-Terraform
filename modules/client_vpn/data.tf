
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

data "aws_acm_certificate" "client_vpn_cert" {
  domain   = var.clientvpn_domain
  statuses = ["ISSUED"]
}