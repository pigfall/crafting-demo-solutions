output "task_private_ip" {
  value = data.external.task.result.private_ip
}
