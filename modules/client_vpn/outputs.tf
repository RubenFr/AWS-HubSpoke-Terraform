
################
# Client VPN
################

output "clientvpn_endpoint_id" {
  description = "ID of the Hub Client VPN Endpoint"
  value       = aws_ec2_client_vpn_endpoint.clientvpn_endpoint.id
}

output "clientvpn_self_service_portal" {
  description = "ID of the Hub Client VPN Endpoint"
  value       = aws_ec2_client_vpn_endpoint.clientvpn_endpoint.self_service_portal_url
}
