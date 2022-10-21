locals {
  client_config = {
    dns      = replace(aws_ec2_client_vpn_endpoint.vpn.dns_name, "*", var.ecs_cluster_name)
    ca_pem   = tls_self_signed_cert.ca.cert_pem
    cert_pem = tls_locally_signed_cert.client.cert_pem
    key_pem  = tls_private_key.client.private_key_pem
  }
}

output "client_config" {
  value     = templatefile("${path.module}/client_config.tftpl", local.client_config)
  sensitive = true
}
