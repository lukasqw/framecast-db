# Contexto de IA — framecast-db

> Topologia de rede e configuração do RDS: [docs/architecture.md](docs/architecture.md)
> Regras de acesso, backup e disaster recovery: [docs/business-rules.md](docs/business-rules.md)
> Workflows CI/CD, actions, variáveis e secrets: [.github/README.md](.github/README.md)

## O que é este repo

Infraestrutura de banco de dados do **Framecast** (pipeline distribuído de extração de frames). Provisiona via Terraform **uma** instância RDS PostgreSQL 16 e o Security Group de acesso a partir do EKS. A instância é compartilhada por `framecast-api` e `framecast-worker`.

O **schema é responsabilidade da `framecast-api`** (GORM AutoMigrate no boot) — este repo entrega a instância em branco. Sem migrations SQL, sem DynamoDB, sem AWS Secrets Manager (a senha vive como GitHub secret `DB_PASSWORD`).

## O que é provisionado

| Recurso | Identificador | Detalhe |
|---|---|---|
| RDS PostgreSQL 16 | `framecast-db` → `framecast_db` | db.t3.micro, gp3, single-AZ, backup 7d |
| Parameter Group | `framecast-db-params` | `rds.force_ssl=0` |
| Subnet Group | `framecast-db-subnet-group` | subnets a/b da VPC default |
| Security Group | `framecast-rds-sg` | ingress 5432 do EKS SG + cluster SG + VPC CIDR |

## Estrutura Terraform

```
terraform/
├── modules/rds/              ← módulo reutilizável (instancia com for_each)
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
└── environments/production/
    ├── main.tf               ← for_each em local.databases (1 entrada) + Security Group
    ├── locals.tf             ← mapa databases{framecast} + subnets + SGs + tags
    ├── variables.tf          ← db_password, db_name, db_username, rds_*
    ├── outputs.tf            ← rds_*, rds_security_group_id
    ├── data.tf               ← remote state infra (framecast/infra/...), VPC, subnets
    ├── backend.tf            ← S3 remote state (key: framecast/db/terraform.tfstate)
    └── provider.tf
```

## Outputs expostos (consumidos por api/worker)

| Output | Sensível |
|--------|----------|
| `rds_address` | sim |
| `rds_port` | não |
| `rds_database_name` (`framecast_db`) | não |
| `rds_username` | sim |
| `rds_endpoint` | sim |
| `rds_security_group_id` | não |
| `aws_region` | não |

## Tecnologias

- **Terraform** — IaC com `for_each` no módulo RDS (preservado com 1 entrada)
- **AWS RDS PostgreSQL 16** — instância única compartilhada
- **GitHub Actions secrets** — senha do banco (`DB_PASSWORD`); o `DATABASE_URL` é montado no deploy de api/worker
- **CloudWatch** — exports de logs do RDS

## Convenções específicas

- Módulo reutilizável em `terraform/modules/rds/` — instanciado via `for_each = local.databases`
- Configuração de produção em `terraform/environments/production/`
- Para adicionar banco futuro: adicionar entrada no mapa `databases` em `locals.tf` + outputs correspondentes
- Nunca commitar `terraform.tfvars` — usar `.tfvars.example` / `TF_VAR_db_password`
- VPC, subnets e SGs do EKS são referenciados via data sources / remote state — não recriados aqui

## Como a IA deve trabalhar neste repo

- **Configuração do banco**: editar `locals.tf` (mapa `databases`) ou variáveis em `variables.tf`
- **Parâmetro PostgreSQL**: editar `terraform/modules/rds/main.tf` (`aws_db_parameter_group`)
- **Connection string**: NÃO há secret AWS aqui; o `DATABASE_URL` é montado no `deploy.yml` de api/worker a partir do GitHub secret `DB_PASSWORD` + output `rds_address`
- **Referenciar recursos de `framecast-infra`**: usar `data "terraform_remote_state" "infra"` em `data.tf`
- Nunca criar VPC, EKS, S3, SQS ou SES aqui — esses recursos são do repo `framecast-infra`
- Schema das tabelas (`users`, `videos`, `outbox_events`) é da `framecast-api` via GORM AutoMigrate — este repo provisiona apenas a instância em branco

## Atenção ao aplicar

- `module "rds"` usa `for_each` — **mudar a chave do mapa (`framecast`) destrói e recria a instância**. Para renomear sem destruição, usar `terraform state mv` antes do `apply`.
- `framecast-infra` deve estar aplicado antes (SGs do EKS no remote state).
- `skip_final_snapshot=true` — destruir o repo apaga o banco sem snapshot; aceitável para a demo.
- State S3 sem lock (DynamoDB) — nunca `apply` em paralelo; o `deploy.yml` usa `concurrency`.
