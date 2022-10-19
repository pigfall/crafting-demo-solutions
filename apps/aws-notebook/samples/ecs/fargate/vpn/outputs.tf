output "vpn_client_config" {
  value = data.external.vpn_client.result.client_config
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.dev-connection-ecs-fargate-vpn.name
}

output "subnet_id" {
  value = aws_subnet.dev-connection-ecs-fargate-vpn.id
}

output "service_launch_type" {
  value = "FARGATE"
}

output "security_group" {
  value = aws_security_group.sg.id
}
