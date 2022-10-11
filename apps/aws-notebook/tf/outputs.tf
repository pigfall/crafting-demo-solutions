output "task-private-ip" {
  value = data.external.task.result.private_ip
}
