# Contexto de IA — oficina-tech-db

> Leia também o [contexto global](../claude.md) antes de trabalhar neste repo.
> Topologia de rede e configuração do RDS: [docs/architecture.md](docs/architecture.md)
> Regras de acesso, backup e disaster recovery: [docs/business-rules.md](docs/business-rules.md)
> Workflows CI/CD, actions, variáveis e secrets: [.github/README.md](.github/README.md)

## O que é este repo

Infraestrutura de dados da plataforma Oficina Tech. Provisiona via Terraform **3 instâncias RDS PostgreSQL 16 independentes** (uma por microsserviço) e **1 tabela DynamoDB** para histórico de ordens de serviço.

## O que é provisionado

| Recurso | Identificador | Microsserviço | Tabelas principais |
|---------|--------------|---------------|--------------------|
| RDS PostgreSQL 16 | `*-ms1` → `db_ms1` | ms-identity | `users`, `customers`, `vehicles` |
| RDS PostgreSQL 16 | `*-ms2` → `db_ms2` | ms-order-service | `service_orders`, `service_order_items` |
| RDS PostgreSQL 16 | `*-ms3` → `db_ms3` | ms-workshop | `services`, `products`, `inventories`, `saga_operations` |
| DynamoDB | `order_history` | ms-order-service | histórico de status das OS (partition: `order_id`, sort: `occurred_at`) |
| Security Group | `*-rds-sg` | todos | regras de acesso dos pods EKS às instâncias RDS |

## Estrutura Terraform

```
terraform/
├── modules/rds/              ← módulo reutilizável (instancia com for_each)
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
└── environments/production/
    ├── main.tf               ← for_each em local.databases + DynamoDB
    ├── locals.tf             ← mapa databases{ms1,ms2,ms3} + subnets + SGs
    ├── variables.tf          ← db_password, rds_*, dynamodb_*
    ├── outputs.tf            ← rds_ms1/ms2/ms3_* + dynamodb_order_history_*
    ├── data.tf               ← remote state infra, VPC, subnets
    ├── backend.tf            ← S3 remote state
    └── provider.tf
```

## Outputs expostos (consumidos pelos MSs)

| Output | Tipo | Sensível |
|--------|------|----------|
| `rds_ms1_address` | host RDS db_ms1 | sim |
| `rds_ms1_port` | porta | não |
| `rds_ms1_database_name` | `db_ms1` | não |
| `rds_ms1_username` | usuário | sim |
| `rds_ms2_address` | host RDS db_ms2 | sim |
| `rds_ms2_port` | porta | não |
| `rds_ms2_database_name` | `db_ms2` | não |
| `rds_ms2_username` | usuário | sim |
| `rds_ms3_address` | host RDS db_ms3 | sim |
| `rds_ms3_port` | porta | não |
| `rds_ms3_database_name` | `db_ms3` | não |
| `rds_ms3_username` | usuário | sim |
| `dynamodb_order_history_table_name` | nome da tabela | não |
| `dynamodb_order_history_table_arn` | ARN da tabela | não |
| `rds_security_group_id` | SG compartilhado | não |

## Tecnologias

- **Terraform** — provisionamento IaC com `for_each` no módulo RDS
- **AWS RDS PostgreSQL 16** — 3 instâncias independentes
- **AWS DynamoDB** — tabela `order_history` com billing PAY_PER_REQUEST
- **AWS Secrets Manager** — armazenamento seguro das senhas do banco
- **CloudWatch** — monitoramento e alertas

## Convenções específicas

- Módulo reutilizável em `terraform/modules/rds/` — instanciado via `for_each = local.databases`
- Configuração de produção em `terraform/environments/production/`
- Para adicionar/remover instância: editar o mapa `databases` em `locals.tf`
- Nunca commitar `terraform.tfvars` — usar `.tfvars.example`
- VPC, subnets e security groups do EKS são referenciados via data sources — não recriados aqui

## Como a IA deve trabalhar neste repo

- **Ao modificar configuração de banco**: editar `locals.tf` (mapa `databases`) ou variáveis em `variables.tf`
- **Ao mudar parâmetro PostgreSQL em todos os bancos**: editar `terraform/modules/rds/main.tf` (o `aws_db_parameter_group`) — vale para as 3 instâncias
- **Ao adicionar novo banco/microsserviço**: adicionar entrada no mapa `databases` em `locals.tf` e os outputs correspondentes em `outputs.tf`
- **Ao modificar DynamoDB**: editar `resource "aws_dynamodb_table" "order_history"` em `main.tf`
- **Para referenciar recursos de `oficina-tech-infra`**: usar `data "terraform_remote_state" "infra"` em `data.tf`
- Nunca criar VPC ou EKS aqui — esses recursos são do repo `oficina-tech-infra`
- Schema das tabelas (migrations SQL ou GORM AutoMigrate) é responsabilidade de cada microsserviço — este repo provisiona apenas as instâncias em branco

## Atenção ao aplicar

`module "rds"` usa `for_each` — **mudar a chave do mapa (`ms1`, `ms2`, `ms3`) destrói e recria a instância**. Para renomear sem destruição, usar `terraform state mv` antes do `apply`.
