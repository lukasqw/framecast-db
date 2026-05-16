# Remote state da infraestrutura principal (EKS, NLB, SGs)
data "terraform_remote_state" "infra" {
  backend = "s3"
  config = {
    bucket = var.tf_state_bucket
    key    = "fiap/infra/terraform.tfstate"
    region = var.aws_region
  }
}

# VPC e Subnets
data "aws_vpc" "main" {
  cidr_block = "172.31.0.0/16"
}

data "aws_subnets" "available" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
}

data "aws_subnet" "selected" {
  for_each = toset(data.aws_subnets.available.ids)
  id       = each.value
}
