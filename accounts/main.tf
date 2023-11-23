locals {
  cidr_vpc = {
    spokes = {
      "${local.account_ids.spoke1}" = "10.10.0.0/22"
      "${local.account_ids.spoke2}" = "10.10.4.0/22"
    }
    hub = {
      egress_vpc     = "10.1.0.0/16"
      ingress_vpc    = "10.2.0.0/16"
      inspection_vpc = "10.3.0.0/16"
    }
  }
}

locals {
  account_ids = {
    hub    = "111111111111"
    spoke1 = "222222222222"
    spoke2 = "333333333333"
  }
}

locals {
  org_vars = {
    region     = "il-central-1"
    number_azs = 2
  }
}

locals {
  principals_to_share_tgw_with = [
    "${local.account_ids.spoke1}",
    "${local.account_ids.spoke2}"
  ]
}

locals {
  client_vpn = {
    create_client_vpn = false
    clientvpn_idp     = "client-vpn-idp"
    clientvpn_domain  = "clientvpn.local"
  }
}
