# oficina-tech-db

Infraestrutura de dados da plataforma Oficina Tech. Provisiona via Terraform 3 instâncias RDS PostgreSQL 16 independentes (uma por microsserviço) e 1 tabela DynamoDB para histórico de ordens de serviço.

## O que este repo provisiona

| Recurso | Identificador AWS | Microsserviço | Banco / Tabela |
|---|---|---|---|
| RDS PostgreSQL 16 | `<project>-ms1` | ms-identity | `db_ms1` |
| RDS PostgreSQL 16 | `<project>-ms2` | ms-order-service | `db_ms2` |
| RDS PostgreSQL 16 | `<project>-ms3` | ms-workshop | `db_ms3` |
| DynamoDB | `order_history` | ms-order-service | histórico de status das OS |
| Security Group | `<project>-rds-sg` | compartilhado | regras de acesso ao PostgreSQL |

O módulo RDS é instanciado com `for_each = local.databases`, criando as 3 instâncias a partir de uma única definição. Migrar de instância única para `for_each` destrói e recria recursos — fazer backup antes de aplicar em ambiente existente.

## Instâncias RDS

As 3 instâncias compartilham os mesmos parâmetros (variáveis globais em `variables.tf`):

| Parâmetro | Valor padrão |
|---|---|
| Engine | PostgreSQL |
| `engine_version` | `16` |
| `instance_class` | `db.t3.micro` |
| `allocated_storage` | 20 GB |
| `max_allocated_storage` | 100 GB (autoscaling) |
| `storage_type` | `gp3` |
| `storage_encrypted` | `true` |
| `multi_az` | `false` |
| `backup_retention_period` | 1 dia |
| `backup_window` | `03:00–04:00` |
| `maintenance_window` | `sun:04:00–sun:05:00` |
| `port` | `5432` |
| `publicly_accessible` | `false` |
| `deletion_protection` | `false` |
| `skip_final_snapshot` | `true` |
| `enabled_cloudwatch_logs_exports` | `["postgresql", "upgrade"]` |
| `performance_insights_enabled` | `false` |
| `rds.force_ssl` (parameter group) | `0` |

Cada instância recebe identifier, database_name e username individuais definidos no mapa `local.databases` em `locals.tf`:

| Chave | identifier | database_name | username |
|---|---|---|---|
| `ms1` | `<project_name>-ms1` | `db_ms1` | `postgres` |
| `ms2` | `<project_name>-ms2` | `db_ms2` | `postgres` |
| `ms3` | `<project_name>-ms3` | `db_ms3` | `postgres` |

A senha (`var.db_password`) é compartilhada entre as 3 instâncias e deve ser fornecida via `terraform.tfvars` ou variável de ambiente `TF_VAR_db_password`.

## DynamoDB

| Atributo | Valor |
|---|---|
| Nome da tabela | `order_history` (configurável via `var.dynamodb_order_history_table`) |
| Billing mode | `PAY_PER_REQUEST` |
| Partition key | `order_id` (tipo `S` — UUID da OS) |
| Sort key | `occurred_at` (tipo `S` — ISO 8601, garante ordenação cronológica) |
| TTL | desabilitado (histórico mantido indefinidamente) |

## Secrets Manager

As senhas do RDS são armazenadas no AWS Secrets Manager pelos microsserviços consumidores. O backend Go de cada microsserviço consome a connection string do Secrets Manager — nunca hardcoded. Este repo não cria os secrets diretamente: a senha é passada via variável `db_password` e os microsserviços são responsáveis por armazená-la no Secrets Manager durante seu próprio deploy.

## Security Group

Um único Security Group (`<project>-rds-sg`) é compartilhado pelas 3 instâncias RDS. Regras de entrada (`ingress`):

| Origem | Protocolo | Porta | Descrição |
|---|---|---|---|
| `local.eks_security_group_id` (SG do módulo security-groups da infra) | TCP | 5432 | PostgreSQL from EKS cluster security group |
| `local.eks_cluster_security_group_id` (SG auto-criado pelo EKS) | TCP | 5432 | PostgreSQL from EKS cluster nodes |
| `data.aws_vpc.main.cidr_block` (`172.31.0.0/16`) | TCP | 5432 | PostgreSQL from VPC CIDR (allows all pods to connect) |

Regra de saída (`egress`):

| Destino | Protocolo | Descrição |
|---|---|---|
| `0.0.0.0/0` | `-1` (all) | Allow all outbound traffic |

## Módulos Terraform

```
terraform/
├── modules/
│   └── rds/                  módulo reutilizável, instanciado via for_each
│       ├── main.tf           aws_db_parameter_group, aws_db_subnet_group, aws_db_instance
│       ├── variables.tf      todas as variáveis de configuração do módulo
│       └── outputs.tf        db_instance_id/arn/endpoint/address/port/name/username, subnet_group
└── environments/
    └── production/
        ├── backend.tf        S3 remote state (key: fiap/db/terraform.tfstate)
        ├── data.tf           remote state infra, aws_vpc (172.31.0.0/16), subnets
        ├── locals.tf         mapa databases{ms1,ms2,ms3}, filtered_subnet_ids, SG IDs do EKS
        ├── main.tf           module.rds (for_each), aws_security_group.rds, regras ingress/egress, aws_dynamodb_table.order_history
        ├── outputs.tf        rds_ms1/ms2/ms3_*, dynamodb_order_history_*, rds_security_group_id
        ├── provider.tf       hashicorp/aws ~> 5.0
        └── variables.tf      db_password, rds_*, dynamodb_*, tf_state_bucket, aws_region, project_name, environment
```

## Variáveis Terraform

Arquivo: `terraform/environments/production/variables.tf`

| Variável | Tipo | Padrão | Sensível | Descrição |
|---|---|---|---|---|
| `aws_region` | `string` | `us-east-1` | não | Região AWS |
| `project_name` | `string` | `EKS-OFICINA-TECH` | não | Nome do projeto (compõe os identifiers do RDS) |
| `environment` | `string` | `production` | não | Ambiente (production, staging, development) |
| `db_password` | `string` | — | sim | Senha compartilhada pelas 3 instâncias RDS |
| `rds_engine_version` | `string` | `16` | não | Versão do PostgreSQL |
| `rds_instance_class` | `string` | `db.t3.micro` | não | Classe da instância RDS |
| `rds_allocated_storage` | `number` | `20` | não | Storage alocado em GB |
| `rds_backup_retention_period` | `number` | `1` | não | Período de retenção de backup em dias |
| `rds_multi_az` | `bool` | `false` | não | Habilitar Multi-AZ |
| `rds_skip_final_snapshot` | `bool` | `true` | não | Pular snapshot final ao destruir |
| `rds_deletion_protection` | `bool` | `false` | não | Habilitar proteção contra deleção |
| `dynamodb_order_history_table` | `string` | `order_history` | não | Nome da tabela DynamoDB |
| `tf_state_bucket` | `string` | `fiap-soat-tf-backend-oficina-tech` | não | Bucket S3 do Terraform state (sobrescrito no CI via TF_STATE_BUCKET) |

## Outputs Terraform

Arquivo: `terraform/environments/production/outputs.tf`

Estes outputs são consumidos pelos microsserviços e pelo pipeline CI/CD da action `tf-apply`.

| Output | Sensível | Descrição |
|---|---|---|
| `rds_ms1_address` | sim | Host do RDS db_ms1 (ms-identity) |
| `rds_ms1_port` | não | Porta do RDS db_ms1 |
| `rds_ms1_database_name` | não | Nome do banco: `db_ms1` |
| `rds_ms1_username` | sim | Usuário do banco db_ms1 |
| `rds_ms2_address` | sim | Host do RDS db_ms2 (ms-order-service) |
| `rds_ms2_port` | não | Porta do RDS db_ms2 |
| `rds_ms2_database_name` | não | Nome do banco: `db_ms2` |
| `rds_ms2_username` | sim | Usuário do banco db_ms2 |
| `rds_ms3_address` | sim | Host do RDS db_ms3 (ms-workshop) |
| `rds_ms3_port` | não | Porta do RDS db_ms3 |
| `rds_ms3_database_name` | não | Nome do banco: `db_ms3` |
| `rds_ms3_username` | sim | Usuário do banco db_ms3 |
| `dynamodb_order_history_table_name` | não | Nome da tabela DynamoDB (`order_history`) |
| `dynamodb_order_history_table_arn` | não | ARN da tabela DynamoDB |
| `rds_security_group_id` | não | ID do Security Group compartilhado pelas 3 instâncias |
| `aws_region` | não | Região AWS utilizada |

## Dependências de remote state

O `data.tf` consome o remote state do repo `oficina-tech-infra`:

```hcl
data "terraform_remote_state" "infra" {
  backend = "s3"
  config = {
    bucket = var.tf_state_bucket
    key    = "fiap/infra/terraform.tfstate"
    region = var.aws_region
  }
}
```

Outputs do `oficina-tech-infra` utilizados:

| Output consumido | Usado em |
|---|---|
| `eks_security_group_id` | `local.eks_security_group_id` → regra ingress `rds_from_eks` |
| `eks_cluster_security_group_id` | `local.eks_cluster_security_group_id` → regra ingress `rds_from_eks_cluster_nodes` |

Nunca renomear esses outputs no `oficina-tech-infra` sem atualizar `locals.tf` neste repo.

## Como fazer deploy

### Pré-requisitos

- Terraform >= 1.0
- AWS CLI configurado com credenciais válidas
- Remote state do `oficina-tech-infra` aplicado (EKS e Security Groups devem existir)
- Acesso ao bucket S3 do Terraform state

### Deploy manual

```bash
cd terraform/environments/production

# Inicializar com o bucket de state correto
terraform init -backend-config="bucket=<TF_STATE_BUCKET>" -backend-config="region=us-east-1"

# Planejar com senha do banco
terraform plan -var="db_password=<senha>"

# Aplicar
terraform apply -var="db_password=<senha>"

# Verificar outputs
terraform output
```

Nunca commitar `terraform.tfvars` com senha. Use a variável de ambiente `TF_VAR_db_password` para evitar exposição em histórico de shell.

### Adicionar ou remover instância RDS

Editar o mapa `databases` em `locals.tf`. Alterar a chave (`ms1`, `ms2`, `ms3`) destrói e recria a instância — usar `terraform state mv` antes do `apply` para renomear sem destruição.

## CI/CD

### Workflows

| Workflow | Gatilho | Descrição |
|---|---|---|
| `ci.yml` | PR para `develop`/`main` (paths: `terraform/**`), push em `develop` | Validação: fmt check, init, validate, tfsec, checkov, terraform plan |
| `release.yml` | Push em `develop` (paths: `terraform/**`), `workflow_dispatch` | Cria ou atualiza PR de release com versão calculada por Conventional Commits |
| `deploy.yml` | PR de `release/*` mergeado em `main`, `workflow_dispatch` | Terraform apply, RDS health check, finaliza tag de release |
| `destroy.yml` | `workflow_dispatch` (confirmação manual) | Terraform destroy |
| `rollback.yml` | `workflow_dispatch` (versão + ambiente) | Aplica Terraform de uma tag anterior sem criar nova tag |

### Composite Actions

```
.github/actions/
├── ci/
│   ├── tf-validate/    fmt check + terraform init (sem backend) + validate
│   ├── tf-security/    tfsec + checkov + upload SARIF para o Security tab
│   ├── tf-plan/        terraform plan + upload artifact + comentário no PR
│   └── tf-structure/   verifica arquivos obrigatórios e estrutura de módulos
├── release/
│   ├── create-pr/      calcula versão (feat: → minor, feat!: → major, demais → patch), cria branch e draft PR
│   ├── update-pr/      sincroniza branch de release com develop e atualiza changelog
│   └── finalize-tag/   cria tag anotada após health check confirmado em produção
└── deploy/
    ├── tf-apply/       terraform init + apply + exporta rds_ms1/ms2/ms3_address como outputs
    └── rds-check/      verifica status "available" das 3 instâncias via AWS CLI; falha aqui impede criação da tag
```

### Fluxo de deploy

```
push em develop (terraform/**)
        |
        v
  [release.yml] — cria ou atualiza PR de release
        |
  merge PR em main
        |
        v
   [deploy.yml]
        |
        v
   tf-apply  (terraform apply)
        |
        v
   rds-check (aws rds describe-db-instances — aguarda status "available" nas 3 instâncias)
        |
        v
   finalize-tag (tag anotada criada somente após health check confirmado)
```

### Secrets e variáveis necessários no GitHub

| Nome | Tipo | Descrição |
|---|---|---|
| `AWS_ACCESS_KEY_ID` | Secret | Access key da AWS |
| `AWS_SECRET_ACCESS_KEY` | Secret | Secret key da AWS |
| `AWS_SESSION_TOKEN` | Secret | Session token (AWS Academy) |
| `DB_PASSWORD` | Secret | Senha compartilhada pelas 3 instâncias RDS |
| `TF_STATE_BUCKET` | Variable | Nome do bucket S3 para o Terraform state |
