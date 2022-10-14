variable "ecs_cluster_name" {
  type        = string
  description = "The name of ECS cluster"
  nullable    = false
  validation {
    condition     = length(var.ecs_cluster_name) > 0
    error_message = "The ecs_cluster_name value must greater than 0."
  }
}

variable "subnet_id" {
  type        = string
  description = "subnet id for ECS service"
  nullable    = false
  validation {
    condition     = length(var.subnet_id) > 0
    error_message = "The subnet_id value must greater than 0."
  }
}

variable "security_groups" {
  type     = string
  nullable = true
}

variable "service_launch_type" {
  type    = string
  default = "FARGATE"
}

variable "ssh_public_key" {
  type    = string
  default = ""
}

variable "task_image" {
  type     = string
  nullable = false
  validation {
    condition     = length(var.task_image) > 0
    error_message = "The task_image value must greater than 0."
  }
}
