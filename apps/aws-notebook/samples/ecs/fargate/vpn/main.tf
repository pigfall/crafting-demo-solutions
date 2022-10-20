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
}

data "external" "tls" {
  program = ["./prepare_openvpn_cert.sh"]
}

data "external" "vpn_client" {
  program = ["./build_openvpn_config.sh"]

  query = {
    vpn_server_dns = aws_ec2_client_vpn_endpoint.dev-connection-ecs-fargate-vpn.dns_name
  }
}

data "aws_iam_policy" "policy" {
  name = "AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "role" {
  name = "craftingDemoEcsTaskExecutionRole"

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

resource "aws_security_group" "sg" {
  name   = "allow_all"
  vpc_id = aws_vpc.dev-connection-ecs-fargate-vpn.id
  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    self             = true
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    self             = true
  }

}

# Create ECS cluster hosted on Fargate
resource "aws_ecs_cluster" "dev-connection-ecs-fargate-vpn" {
  name = "crafting-notebook-demo"

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
  tags = {
    Name = "crafting-notebook-demo"
  }
}

# Create a subnet for VPC
resource "aws_subnet" "dev-connection-ecs-fargate-vpn" {
  vpc_id     = aws_vpc.dev-connection-ecs-fargate-vpn.id
  cidr_block = "10.0.0.0/17"

  tags = {
    Name = "crafting-notebook-demo-subnet-a"
  }
}

# Create PrivateLink to access ECR without internet connection
resource "aws_vpc_endpoint" "dev-connection-ecs-fargate-vpn-s3" {
  vpc_id            = aws_vpc.dev-connection-ecs-fargate-vpn.id
  service_name      = "com.amazonaws.us-west-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_vpc.dev-connection-ecs-fargate-vpn.main_route_table_id]

  tags = {
    Name = "crafting-notebook-demo-s3"
  }
}

resource "aws_vpc_endpoint" "dev-connection-ecs-fargate-vpn-ecr-dkr" {
  vpc_id              = aws_vpc.dev-connection-ecs-fargate-vpn.id
  service_name        = "com.amazonaws.us-west-1.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.dev-connection-ecs-fargate-vpn.id]
  security_group_ids  = [aws_security_group.sg.id]

  tags = {
    Name = "crafting-notebook-demo-ecr-dkr"
  }
}

resource "aws_vpc_endpoint" "dev-connection-ecs-fargate-vpn-ecr-api" {
  vpc_id              = aws_vpc.dev-connection-ecs-fargate-vpn.id
  service_name        = "com.amazonaws.us-west-1.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.dev-connection-ecs-fargate-vpn.id]
  security_group_ids  = [aws_security_group.sg.id]

  tags = {
    Name = "crafting-notebook-demo-ecr-api"
  }
}

resource "aws_vpc_endpoint" "dev-connection-ecs-fargate-vpn-logs" {
  vpc_id              = aws_vpc.dev-connection-ecs-fargate-vpn.id
  service_name        = "com.amazonaws.us-west-1.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.dev-connection-ecs-fargate-vpn.id]
  security_group_ids  = [aws_security_group.sg.id]

  tags = {
    Name = "crafting-notebook-demo-logs"
  }
}

resource "aws_acm_certificate" "cert" {
  private_key      = file(data.external.tls.result.server_key)
  certificate_body = file(data.external.tls.result.server_cert)

  certificate_chain = file(data.external.tls.result.ca_cert)
}

#data "aws_acm_certificate" "dev-connection-ecs-fargate-vpn" {
#  domain   = "notebook.server.crafting.demo"
#  statuses = ["ISSUED"]
#}

# Create Client VPN Endpoint
resource "aws_ec2_client_vpn_endpoint" "dev-connection-ecs-fargate-vpn" {
  client_cidr_block      = "172.17.0.0/16"
  server_certificate_arn = aws_acm_certificate.cert.arn
  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = aws_acm_certificate.cert.arn
  }
  connection_log_options {
    enabled = false
  }

  vpc_id             = aws_vpc.dev-connection-ecs-fargate-vpn.id
  security_group_ids = [aws_security_group.sg.id]

  tags = {
    Name = "crafting-notebook-demo"
  }
}

# Associate subnet with Client VPN endpoint
resource "aws_ec2_client_vpn_network_association" "dev-connection-ecs-fargate-vpn" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.dev-connection-ecs-fargate-vpn.id
  subnet_id              = aws_subnet.dev-connection-ecs-fargate-vpn.id
}

# Add Authorization Rule to Client VPN endpoint
resource "aws_ec2_client_vpn_authorization_rule" "dev-connection-ecs-fargate-vpn" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.dev-connection-ecs-fargate-vpn.id
  target_network_cidr    = aws_subnet.dev-connection-ecs-fargate-vpn.cidr_block
  authorize_all_groups   = true
}
