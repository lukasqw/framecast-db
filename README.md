# framecast-db

Infraestrutura de banco de dados do **Framecast** (pipeline distribuído de extração de frames). Provisiona via Terraform **uma** instância RDS PostgreSQL 16 e o Security Group de acesso a partir do EKS. A senha do banco é guardada como GitHub Actions secret (`DB_PASSWORD`), não no AWS Secrets Manager.

O **schema é responsabilidade da `framecast-api`** (GORM AutoMigrate no boot) — este repo entrega a instância em branco. A mesma instância é compartilhada por `framecast-api` e `framecast-worker`, que operam sobre as mesmas tabelas (`videos`) usando o mesmo `DATABASE_URL`.

## O que este repo provisiona

| Recurso | Identificador AWS | Detalhe |
|---|---|---|
| RDS PostgreSQL 16 | `framecast-db` → banco `framecast_db` | `db.t3.micro`, gp3 20→100GB, encrypted, single-AZ, backup 7d |
| Parameter Group | `framecast-db-params` | `rds.force_ssl=0` (paridade dev/LocalStack) |
| Subnet Group | `framecast-db-subnet-group` | subnets `us-east-1a/b` da VPC default |
| Security Group | `framecast-rds-sg` | ingress 5432 do EKS SG + cluster SG + VPC CIDR; egress livre |

O módulo RDS é instanciado com `for_each = local.databases` (1 entrada), preservando o padrão do repo base e permitindo adicionar bancos no futuro editando `locals.tf`. **Mudar a chave `framecast` do mapa destrói e recria a instância** — usar `terraform state mv` para renomear.

## Instância RDS

| Parâmetro | Valor padrão |
|---|---|
| Engine | PostgreSQL 16 |
| `instance_class` | `db.t3.micro` |
| `allocated_storage` | 20 GB (autoscaling até 100 GB) |
| `storage_type` | `gp3` |
| `storage_encrypted` | `true` |
| `multi_az` | `false` (single-AZ, custo da demo) |
| `backup_retention_period` | 7 dias |
| `port` | `5432` |
| `publicly_accessible` | `false` |
| `deletion_protection` | `false` |
| `skip_final_snapshot` | `true` (instância efêmera para a demo) |
| `rds.force_ssl` (parameter group) | `0` (consumidor usa `sslmode=require` em prod) |

| Chave do mapa | identifier | database_name | username |
|---|---|---|---|
| `framecast` | `framecast-db` | `framecast_db` | `framecast` |

A senha (`var.db_password`) é fornecida via `TF_VAR_db_password` / secret `DB_PASSWORD` — nunca commitada.

## Credenciais (sem Secrets Manager)

Este repo **não** cria secret no AWS Secrets Manager. A senha do banco vive como **GitHub Actions secret** `DB_PASSWORD` (mesmo valor de `TF_VAR_db_password`). O `deploy.yml` de `framecast-api`/`framecast-worker` monta o `DATABASE_URL` a partir desse secret + o output `rds_address` (lido via `terraform_remote_state.db`) e o injeta como `Secret`/env no rollout do EKS.

Motivo: o `framecast-infra` não provisiona External Secrets Operator nem o CSI driver, e o app Go lê `DATABASE_URL` de env var (não do SDK do Secrets Manager). Como a senha já está no GitHub e a AWS Academy não tem rotação automática, um secret AWS seria duplicação sem benefício.

## Security Group

`framecast-rds-sg` — regras de entrada (`ingress`):

| Origem | Protocolo | Porta | Descrição |
|---|---|---|---|
| `local.eks_security_group_id` (SG do módulo security-groups da infra) | TCP | 5432 | PostgreSQL from EKS cluster security group |
| `local.eks_cluster_security_group_id` (SG auto-criado pelo EKS) | TCP | 5432 | PostgreSQL from EKS cluster nodes |
| `data.aws_vpc.main.cidr_block` (`172.31.0.0/16`) | TCP | 5432 | PostgreSQL from VPC CIDR (allows all pods to connect) |

Saída (`egress`): `0.0.0.0/0` em todos os protocolos.

## Estrutura Terraform

```
terraform/
├── modules/
│   └── rds/                  módulo reutilizável, instanciado via for_each
│       ├── main.tf           aws_db_parameter_group, aws_db_subnet_group, aws_db_instance
│       ├── variables.tf      variáveis de configuração do módulo
│       └── outputs.tf        db_instance_id/arn/endpoint/address/port/name/username, subnet_group
└── environments/
    └── production/
        ├── backend.tf        S3 remote state (key: framecast/db/terraform.tfstate)
        ├── data.tf           remote state infra (framecast/infra/...), aws_vpc (172.31.0.0/16), subnets
        ├── locals.tf         mapa databases{framecast}, filtered_subnet_ids, SG IDs do EKS, tags
        ├── main.tf           module.rds (for_each), aws_security_group.rds, regras ingress/egress
        ├── outputs.tf        rds_address/port/database_name/username/endpoint, rds_security_group_id
        ├── provider.tf       hashicorp/aws ~> 5.0
        └── variables.tf      db_password, db_name, db_username, rds_*, tf_state_bucket, aws_region, project_name
```

## Variáveis Terraform

| Variável | Tipo | Padrão | Sensível | Descrição |
|---|---|---|---|---|
| `aws_region` | `string` | `us-east-1` | não | Região AWS |
| `project_name` | `string` | `framecast` | não | Nome do projeto (compõe o identifier do RDS) |
| `environment` | `string` | `production` | não | Ambiente |
| `db_password` | `string` | — | sim | Senha master do RDS |
| `db_name` | `string` | `framecast_db` | não | Nome do banco criado na instância |
| `db_username` | `string` | `framecast` | não | Usuário master (owner único) |
| `rds_engine_version` | `string` | `16` | não | Versão do PostgreSQL |
| `rds_instance_class` | `string` | `db.t3.micro` | não | Classe da instância RDS |
| `rds_allocated_storage` | `number` | `20` | não | Storage alocado em GB |
| `rds_backup_retention_period` | `number` | `7` | não | Retenção de backup em dias |
| `rds_multi_az` | `bool` | `false` | não | Habilitar Multi-AZ |
| `rds_skip_final_snapshot` | `bool` | `true` | não | Pular snapshot final ao destruir |
| `rds_deletion_protection` | `bool` | `false` | não | Proteção contra deleção |
| `tf_state_bucket` | `string` | `fiap-soat-tf-backend-framecast` | não | Bucket S3 do state (sobrescrito no CI via TF_STATE_BUCKET) |

## Outputs Terraform

Consumidos por `framecast-api`/`framecast-worker` (deploy.yml → ConfigMap/Secret) e pela action `tf-apply`.

| Output | Sensível | Descrição |
|---|---|---|
| `rds_address` | sim | Host do RDS framecast_db (sem porta) |
| `rds_port` | não | Porta do RDS |
| `rds_database_name` | não | Nome do banco: `framecast_db` |
| `rds_username` | sim | Usuário master |
| `rds_endpoint` | sim | Endpoint completo (host:port) |
| `rds_security_group_id` | não | ID do Security Group da instância |
| `aws_region` | não | Região AWS utilizada |

## Dependências de remote state

O `data.tf` consome o remote state do repo `framecast-infra`:

```hcl
data "terraform_remote_state" "infra" {
  backend = "s3"
  config = {
    bucket = var.tf_state_bucket
    key    = "framecast/infra/terraform.tfstate"
    region = var.aws_region
  }
}
```

Outputs do `framecast-infra` utilizados:

| Output consumido | Usado em |
|---|---|
| `eks_security_group_id` | `local.eks_security_group_id` → regra ingress `rds_from_eks` |
| `eks_cluster_security_group_id` | `local.eks_cluster_security_group_id` → regra ingress `rds_from_eks_cluster_nodes` |

`framecast-infra` deve estar aplicado **antes** deste repo (os SGs do EKS precisam existir no remote state).

## Contrato de saída

```
DATABASE_URL = postgres://framecast:<senha>@<rds_address>:5432/framecast_db?sslmode=require
```

Montado no `deploy.yml` de `framecast-api`/`framecast-worker` a partir do GitHub secret `DB_PASSWORD` (senha) + o output `rds_address` (via `terraform_remote_state.db`), e injetado como `Secret`/env no rollout do EKS.

## Como fazer deploy

### Pré-requisitos

- Terraform >= 1.0
- AWS CLI configurado
- Remote state do `framecast-infra` aplicado (EKS + Security Groups existentes)
- Acesso ao bucket S3 do Terraform state

### Deploy manual

```bash
cd terraform/environments/production
terraform init -backend-config="bucket=<TF_STATE_BUCKET>" -backend-config="region=us-east-1"
export TF_VAR_db_password=<senha>
terraform plan
terraform apply
terraform output
```

Nunca commitar `terraform.tfvars` com senha. Use `TF_VAR_db_password`.

## CI/CD

| Workflow | Gatilho | Descrição |
|---|---|---|
| `ci.yml` | PR para `develop`/`main` (paths: `terraform/**`), push em `develop` | Validate, security scan, terraform plan |
| `release.yml` | Push em `develop` (paths: `terraform/**`), `workflow_dispatch` | Cria/atualiza PR de release (Conventional Commits) |
| `deploy.yml` | PR de `release/*` mergeado em `main`, `workflow_dispatch` | Terraform apply, RDS health check, finaliza tag |
| `destroy.yml` | `workflow_dispatch` (confirmação manual) | Terraform destroy |
| `rollback.yml` | `workflow_dispatch` (versão + ambiente) | Aplica Terraform de tag anterior |

A tag de release só é criada **após** o `rds-check` confirmar a instância `framecast_db` em `available`.

### Secrets e variáveis no GitHub

| Nome | Tipo | Descrição |
|---|---|---|
| `AWS_ACCESS_KEY_ID` | Secret | Access key da AWS |
| `AWS_SECRET_ACCESS_KEY` | Secret | Secret key da AWS |
| `AWS_SESSION_TOKEN` | Secret | Session token (AWS Academy) |
| `DB_PASSWORD` | Secret | Senha master do RDS (`TF_VAR_db_password`) |
| `TF_STATE_BUCKET` | Variable | Bucket S3 do Terraform state |

