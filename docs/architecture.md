# Arquitetura — framecast-db

## Visão Geral

Provisionamento de **uma** instância RDS PostgreSQL 16 na AWS. O banco roda na VPC default gerenciada por `framecast-infra`, acessível apenas pelos pods do EKS. É compartilhado por `framecast-api` (escreve `users`, `videos`, `outbox_events`) e `framecast-worker` (atualiza `videos` — colunas de lease/status).

## Diagrama

```
┌─────────────────────────────────────────────────┐
│                   AWS VPC default                │
│  (descoberta via CIDR 172.31.0.0/16)             │
│                                                  │
│  ┌──────────────────┐    ┌──────────────────┐    │
│  │  Subnet          │    │  Subnet          │    │
│  │  (AZ us-east-1a) │    │  (AZ us-east-1b) │    │
│  │                  │    │                  │    │
│  │   ┌───────────────────────────────┐     │    │
│  │   │  RDS framecast_db (single-AZ) │     │    │
│  │   │  PostgreSQL 16 · db.t3.micro  │     │    │
│  │   └───────────────────────────────┘     │    │
│  └──────────────────┘    └──────────────────┘    │
│              ▲                                    │
│              │ framecast-rds-sg (porta 5432)      │
│              │ EKS SG + EKS cluster SG + VPC CIDR │
│              │                                    │
│  ┌───────────┴──────────┐                         │
│  │   EKS Nodes          │                         │
│  │   (api + worker pods)│                         │
│  └──────────────────────┘                         │
└─────────────────────────────────────────────────┘

  Senha: GitHub secret DB_PASSWORD → deploy.yml de api/worker
  monta DATABASE_URL (DB_PASSWORD + output rds_address)
```

## Estrutura do Projeto

```
framecast-db/
├── terraform/
│   ├── modules/
│   │   └── rds/               ← módulo reutilizável do RDS
│   │       ├── main.tf            ← db instance, parameter group, subnet group
│   │       ├── variables.tf       ← inputs do módulo
│   │       └── outputs.tf         ← endpoint, address, port, name, username
│   └── environments/
│       └── production/        ← configuração de produção
│           ├── main.tf            ← module.rds (for_each) + Security Group
│           ├── data.tf            ← remote state infra, VPC, subnets
│           ├── locals.tf          ← mapa databases{framecast}, subnets, SGs, tags
│           ├── backend.tf         ← remote state S3 (framecast/db/...)
│           ├── variables.tf
│           └── outputs.tf
└── docs/
```

## Configuração do RDS

| Parâmetro | Valor |
|-----------|-------|
| Engine | PostgreSQL 16 |
| Instance class | db.t3.micro |
| Storage | 20GB gp3, auto-scaling até 100GB |
| Multi-AZ | Desabilitado (single-AZ, custo da demo) |
| Backup | Retenção de 7 dias |
| Encryption | Habilitado (AWS KMS) |
| Public access | Desabilitado |
| `rds.force_ssl` | `0` (consumidor usa `sslmode=require` em produção) |

## Rede

- A VPC default é descoberta via CIDR `172.31.0.0/16` em `data.tf`.
- O subnet group usa as subnets das AZs `us-east-1a` e `us-east-1b` (RDS exige ≥ 2 AZs).
- A instância **não** é publicamente acessível — só os pods do EKS conectam, via `framecast-rds-sg`.

## Segurança

- RDS sem acesso direto da internet (`publicly_accessible = false`).
- `framecast-rds-sg` permite entrada na porta 5432 apenas do EKS SG, do EKS cluster SG (auto-criado) e do CIDR da VPC.
- A senha do banco é um **GitHub Actions secret** (`DB_PASSWORD`) — não há AWS Secrets Manager neste repo.
- O `deploy.yml` de api/worker monta o `DATABASE_URL` (`DB_PASSWORD` + output `rds_address`) e injeta como `Secret`/env no EKS — nunca hardcoded.

## Remote State

Este repo lê o state de `framecast-infra` (`key = framecast/infra/terraform.tfstate`) para obter:
- `eks_security_group_id`
- `eks_cluster_security_group_id`

Configurado em `terraform/environments/production/data.tf`. A VPC e as subnets são descobertas por data source (fallback ao CIDR fixo).

## Outputs

Expostos ao ecossistema (consumidos por api/worker e pela action `tf-apply`):
- `rds_address` / `rds_endpoint` — host / host:port
- `rds_database_name` — `framecast_db`
- `rds_username` — usuário master
- `rds_security_group_id` — SG da instância
