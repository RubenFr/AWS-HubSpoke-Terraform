###################
# Outputs
###################

output "VPCs" {
  value = {
    egress     = module.hub.egress_vpc
    ingress    = module.hub.ingress_vpc
    inspection = module.hub.inspection_vpc
  }
}

output "hub_tgw_id" {
  value = module.hub.hub_tgw_id
}

output "hub_firewall" {
  value = {
    firewall_arn = module.hub.hub_firewall_arn
    firewall_policy_arn = module.hub.hub_firewall_policy_arn
  }
}

output "clientvpn" {
  value = module.accounts.client_vpn.create_client_vpn ? {
    id = module.client_vpn[0].clientvpn_endpoint_id
    self_service_portal_url = module.client_vpn[0].clientvpn_self_service_portal
  } : null
}