data "external" "task" {
  program = ["${path.module}/get-task-ip.sh"]
}

output "task-private-ip"{
  value = data.external.task.result.task_private_ip
}
