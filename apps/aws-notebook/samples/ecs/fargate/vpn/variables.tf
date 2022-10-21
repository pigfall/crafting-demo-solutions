variable "ecs_cluster_name" {
  type        = string
  description = "the name of ecs cluster"
  nullable    = false
  validation {
    condition     = length(var.ecs_cluster_name) > 0
    error_message = "The ecs_cluster_name value must greater than 0."
  }
}
