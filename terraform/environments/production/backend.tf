terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    key = "fiap/db/terraform.tfstate"
    # bucket e region são fornecidos em tempo de execução via -backend-config
    # Configure TF_STATE_BUCKET como variável do repositório no GitHub Actions
  }
}
