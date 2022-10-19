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
  region = "us-west-1"
}

data "external" "tls" {
  program = ["./prepare_openvpn_cert.sh"]
}

output "ca_cert"{
  value = file(data.external.tls.result.ca_cert)
}
