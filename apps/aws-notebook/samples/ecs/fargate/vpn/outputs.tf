output "ecs_cluster_name" {
  value = aws_ecs_cluster.cluster.name
}

output "subnet_id" {
  value = aws_subnet.subnet.id
}

output "service_launch_type" {
  value = "FARGATE"
}

