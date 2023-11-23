
provider "aws" {
  region                 = module.accounts.org_vars.region
  skip_region_validation = true

  default_tags {
    tags = {
      Application = "Spoke"
      Created_By  = "Terraform"
    }
  }
}

data "aws_caller_identity" "current" {}

module "accounts" {
  source = "../../accounts"
}

module "spoke" {
  source = "../../modules/spoke"

  region                 = module.accounts.org_vars.region
  number_azs             = module.accounts.org_vars.number_azs
  spoke_vpc_cidr_block   = module.accounts.cidr_vpc.spokes[data.aws_caller_identity.current.account_id]
}
