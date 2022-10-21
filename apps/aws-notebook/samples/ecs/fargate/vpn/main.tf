terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  default_tags {
    tags = {
      Name = "sandbox-${var.ecs_cluster_name}"
    }
  }
}



data "aws_iam_policy" "policy" {
  name = "AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "role" {
  name = "${var.ecs_cluster_name}-EcsTaskExecutionRole"

  assume_role_policy = <<EOF
    {
      "Version": "2012-10-17",
        "Statement": [
        {
          "Sid": "",
          "Effect": "Allow",
          "Principal": {
            "Service": "ecs-tasks.amazonaws.com"
          },
          "Action": "sts:AssumeRole"
        }
        ]
    }
  EOF
}

resource "aws_iam_role_policy_attachment" "policy_attach" {
  role       = aws_iam_role.role.name
  policy_arn = data.aws_iam_policy.policy.arn
}


# Create ECS cluster hosted on Fargate
resource "aws_ecs_cluster" "cluster" {
  name = var.ecs_cluster_name

  setting {
    name  = "containerInsights"
    value = "disabled"
  }
}

# Create a VPC for ECS cluster
resource "aws_vpc" "dev-connection-ecs-fargate-vpn" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

# Create a subnet for VPC
resource "aws_subnet" "subnet" {
  vpc_id     = aws_vpc.dev-connection-ecs-fargate-vpn.id
  cidr_block = "10.0.0.0/17"

}

# Create PrivateLink to access ECR without internet connection
resource "aws_vpc_endpoint" "dev-connection-ecs-fargate-vpn-s3" {
  vpc_id            = aws_vpc.dev-connection-ecs-fargate-vpn.id
  service_name      = "com.amazonaws.us-west-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_vpc.dev-connection-ecs-fargate-vpn.main_route_table_id]

}

resource "aws_vpc_endpoint" "dev-connection-ecs-fargate-vpn-ecr-dkr" {
  vpc_id              = aws_vpc.dev-connection-ecs-fargate-vpn.id
  service_name        = "com.amazonaws.us-west-1.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.subnet.id]

}

resource "aws_vpc_endpoint" "dev-connection-ecs-fargate-vpn-ecr-api" {
  vpc_id              = aws_vpc.dev-connection-ecs-fargate-vpn.id
  service_name        = "com.amazonaws.us-west-1.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.subnet.id]

}

resource "aws_vpc_endpoint" "dev-connection-ecs-fargate-vpn-logs" {
  vpc_id              = aws_vpc.dev-connection-ecs-fargate-vpn.id
  service_name        = "com.amazonaws.us-west-1.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.subnet.id]
}


# Create Client VPN Endpoint
resource "aws_ec2_client_vpn_endpoint" "vpn" {
  client_cidr_block      = "172.17.0.0/16"
  server_certificate_arn = aws_acm_certificate.server.arn
  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = aws_acm_certificate.ca.arn
  }
  connection_log_options {
    enabled = false
  }

  vpc_id = aws_vpc.dev-connection-ecs-fargate-vpn.id

}

# Associate subnet with Client VPN endpoint
resource "aws_ec2_client_vpn_network_association" "dev-connection-ecs-fargate-vpn" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  subnet_id              = aws_subnet.subnet.id
}

# Add Authorization Rule to Client VPN endpoint
resource "aws_ec2_client_vpn_authorization_rule" "dev-connection-ecs-fargate-vpn" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  target_network_cidr    = aws_subnet.subnet.cidr_block
  authorize_all_groups   = true
}
