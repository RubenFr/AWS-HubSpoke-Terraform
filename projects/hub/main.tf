
provider "aws" {
  region                 = module.accounts.org_vars.region
  skip_region_validation = true

  default_tags {
    tags = {
      Environment = "Dev"
      Application = "Hub"
      Created_By  = "Terraform"
    }
  }
}

module "accounts" {
  source = "../../accounts"
}


module "hub" {
  source = "../../modules/hub"

  region                    = module.accounts.org_vars.region
  number_azs                = module.accounts.org_vars.number_azs
  egress_vpc_cidr_block     = module.accounts.cidr_vpc.hub.egress_vpc
  ingress_vpc_cidr_block    = module.accounts.cidr_vpc.hub.ingress_vpc
  inspection_vpc_cidr_block = module.accounts.cidr_vpc.hub.inspection_vpc
  ram_principals            = module.accounts.principals_to_share_tgw_with
}

module "client_vpn" {
  source = "../../modules/client_vpn"

  count                = module.accounts.client_vpn.create_client_vpn ? 1 : 0
  region               = module.accounts.org_vars.region
  clientvpn_vpc_id     = module.hub.ingress_vpc.id
  clientvpn_subnet_ids = module.hub.ingress_vpc.clientvpn_subnet_ids
  clientvpn_idp_id     = module.accounts.client_vpn.clientvpn_idp
  clientvpn_domain     = module.accounts.client_vpn.clientvpn_domain
}
