# Contexto de IA — oficina-tech-db

> Leia também o [contexto global](../claude.md) antes de trabalhar neste repo.
> Topologia de rede e configuração do RDS: [docs/architecture.md](docs/architecture.md)
> Regras de acesso, backup e disaster recovery: [docs/business-rules.md](docs/business-rules.md)
> Workflows CI/CD, actions, variáveis e secrets: [.github/README.md](.github/README.md)

## O que é este repo

Infraestrutura do banco de dados PostgreSQL da plataforma Oficina Tech. Provisiona via Terraform o RDS PostgreSQL 16 na AWS dentro da VPC padrão referenciada por `oficina-tech-infra`.

## Domínio deste repo

Exclusivamente infraestrutura de dados:
- Instância RDS PostgreSQL
- Security group do banco (quem pode conectar)
- Subnet group (onde o banco é criado na VPC)
- Backups e parâmetros do banco
- Secret no AWS Secrets Manager com a connection string

## Tecnologias

- **Terraform** — provisionamento IaC
- **AWS RDS** — banco de dados gerenciado
- **AWS Secrets Manager** — armazenamento seguro da senha do banco
- **CloudWatch** — monitoramento e alertas

## Convenções específicas

- Módulo reutilizável em `terraform/modules/rds/`
- Configuração de produção em `terraform/environments/production/`
- Nunca commitar `terraform.tfvars` — usar `.tfvars.example`
- VPC, subnets e security groups do EKS são referenciados via **data sources** (não recriados aqui)

## Como a IA deve trabalhar neste repo

- Ao modificar configurações do banco: mexer nos módulos em `terraform/modules/rds/`
- Ao adicionar parâmetro do PostgreSQL: usar `aws_db_parameter_group`
- Para referenciar recursos de `oficina-tech-infra`: usar `data "terraform_remote_state"` em `terraform/environments/production/data.tf`
- Nunca criar VPC ou EKS aqui — esses recursos são do repo `oficina-tech-infra`
- Consultar [docs/architecture.md](docs/architecture.md) para topologia de rede, configuração do RDS e outputs expostos
- Consultar [docs/business-rules.md](docs/business-rules.md) para regras de acesso, backup, mudanças seguras e disaster recovery
- Schema do banco (tabelas, migrations) é responsabilidade do repo `oficina-tech` — este repo apenas provisiona a instância em branco
