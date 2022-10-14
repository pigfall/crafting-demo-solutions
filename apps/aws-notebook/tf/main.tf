terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=4"
    }
  }
}


provider "aws" {
  default_tags {
    tags = {
      Sandbox = data.external.env.result.sandbox_name
    }
  }
}

data "aws_ecs_cluster" "cluster" {
  cluster_name = var.ecs_cluster_name
}

data "external" "env" {
  program = ["${path.module}/env.sh"]
}

data "external" "task" {
  program = ["${path.module}/get-task-ip.sh"]
  query = {
    ecs_cluster_name = data.aws_ecs_cluster.cluster.cluster_name
    ecs_service_name = resource.aws_ecs_service.notebook.name
  }
}

data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
}

# Create a task definition 
resource "aws_ecs_task_definition" "notebook" {
  family                   = "notebook_${data.external.env.result.sandbox_id}"
  requires_compatibilities = ["FARGATE", "EC2"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
  task_role_arn      = data.aws_iam_role.ecs_task_execution_role.arn
  execution_role_arn = data.aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name      = "notebook"
      image     = var.task_image
      essential = true
      environment = [
        {
          name  = "PUBLIC_KEY"
          value = var.ssh_public_key
        }
      ]
      portMappings = [
        {
          containerPort = 22
          hostPort      = 22
        }
      ]
    }
  ])
}

# Create a service
resource "aws_ecs_service" "notebook" {
  launch_type         = var.service_launch_type
  task_definition     = aws_ecs_task_definition.notebook.arn
  name                = "notebook_${data.external.env.result.sandbox_id}"
  cluster             = data.aws_ecs_cluster.cluster.id
  scheduling_strategy = "REPLICA"
  desired_count       = 1
  network_configuration {
    subnets          = [var.subnet_id]
    assign_public_ip = false
    security_groups  = split(",", var.security_groups)
  }
}
