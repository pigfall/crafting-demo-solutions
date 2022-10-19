output "vpn_client_config"{
  value = data.external.vpn_client.result.client_config
}
