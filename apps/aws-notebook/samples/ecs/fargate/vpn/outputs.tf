output "ecs_cluster_name" {
  value = aws_ecs_cluster.cluster.name
}

output "subnet_id" {
  value = aws_subnet.subnet.id
}

output "service_launch_type" {
  value = "FARGATE"
}

output "security_group" {
  value = aws_security_group.sg.id
}
