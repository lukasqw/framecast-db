terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "fiap-soat-tf-backend-bispo-730335587750"
    key    = "fiap/db/terraform.tfstate"
    region = "us-east-1"
  }
}
