# Local Values
locals {
  # Database configuration
  db_name     = replace(lower(var.project_name), "-", "_")
  db_username = "postgres"

  # Multiple subnets across AZs (required by AWS - minimum 2 AZs)
  filtered_subnet_ids = [
    for subnet in data.aws_subnet.selected : subnet.id
    if contains(["${var.aws_region}a", "${var.aws_region}b"], subnet.availability_zone)
  ]

  # SG IDs do EKS (do remote state da infra)
  eks_security_group_id         = data.terraform_remote_state.infra.outputs.eks_security_group_id
  eks_cluster_security_group_id = data.terraform_remote_state.infra.outputs.eks_cluster_security_group_id

  # Tags
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Repository  = "oficina-tech-db"
  }
}
