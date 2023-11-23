###################
# Outputs
###################

output "spoke_vpc" {
  value = module.spoke.vpc
}

output "tgw_attachment" {
  value = module.spoke.tgw_attachment
}
