ENV ?= production
TF_DIR = terraform/environments/$(ENV)

.PHONY: init plan apply destroy fmt validate

init:
	cd $(TF_DIR) && terraform init

plan:
	cd $(TF_DIR) && terraform plan

apply:
	cd $(TF_DIR) && terraform apply

destroy:
	cd $(TF_DIR) && terraform destroy

fmt:
	terraform fmt -recursive

validate:
	cd $(TF_DIR) && terraform validate
