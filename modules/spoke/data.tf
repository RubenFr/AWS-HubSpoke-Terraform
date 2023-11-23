data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

data "aws_ec2_transit_gateway" "hub_tgw" {
  filter {
    name   = "state"
    values = ["available"]
  }
}
