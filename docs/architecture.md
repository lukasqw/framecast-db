# Arquitetura — oficina-tech-db

## Visão Geral

Provisionamento do banco de dados PostgreSQL 16 na AWS RDS. O banco roda em subnet privada dentro da VPC gerenciada por `oficina-tech-infra`, acessível apenas pelos pods do EKS.

## Diagrama

```
┌─────────────────────────────────────────────────┐
│                   AWS VPC                        │
│  (criada por oficina-tech-infra)                │
│                                                 │
│  ┌──────────────────┐    ┌──────────────────┐  │
│  │  Subnet Privada  │    │  Subnet Privada  │  │
│  │  (AZ us-east-1a) │    │  (AZ us-east-1b) │  │
│  │                  │    │                  │  │
│  │  ┌────────────┐  │    │  ┌────────────┐  │  │
│  │  │  RDS       │  │    │  │  RDS       │  │  │
│  │  │  Primary   │◄─┼────┼─►│  Standby  │  │  │
│  │  │  (Multi-AZ)│  │    │  │  (failover)│  │  │
│  │  └────────────┘  │    │  └────────────┘  │  │
│  └──────────────────┘    └──────────────────┘  │
│              ▲                                  │
│              │ Security Group (porta 5432)       │
│              │ Apenas: EKS Node SG              │
│              │                                  │
│  ┌───────────┴──────────┐                       │
│  │   EKS Nodes          │                       │
│  │   (oficina-tech pods)│                       │
│  └──────────────────────┘                       │
└─────────────────────────────────────────────────┘
```

## Estrutura do Projeto

```
oficina-tech-db/
├── terraform/
│   ├── modules/
│   │   └── rds/               ← módulo reutilizável do RDS
│   │       ├── main.tf            ← db instance, parameter group, subnet group
│   │       ├── variables.tf       ← inputs do módulo
│   │       └── outputs.tf         ← endpoint, port, secret ARN
│   └── environments/
│       └── production/        ← configuração de produção
│           ├── main.tf            ← instancia o módulo rds
│           ├── data.tf            ← data sources (VPC, subnets de infra)
│           ├── backend.tf         ← remote state S3
│           ├── variables.tf
│           └── outputs.tf
└── docs/
```

## Configuração do RDS

| Parâmetro | Valor |
|-----------|-------|
| Engine | PostgreSQL 16 |
| Instance class | db.t3.micro |
| Storage | 20GB gp2, auto-scaling até 100GB |
| Multi-AZ | Configurável (desabilitado por padrão para custo) |
| Backup | Retenção de 7 dias, janela automática |
| Manutenção | Janela semanal configurada |
| Encryption | Habilitado (AWS KMS) |
| Public access | Desabilitado |

## Segurança

- RDS em **subnet privada** — sem acesso direto da internet
- Security group permite entrada na **porta 5432 apenas** do security group dos nodes EKS
- Senha gerada aleatoriamente pelo Terraform e armazenada no **AWS Secrets Manager**
- Backend Go consome a connection string do Secrets Manager (nunca hardcoded)

## Remote State

Este repo lê o state de `oficina-tech-infra` para obter:
- VPC ID
- IDs das subnets privadas
- Security Group ID dos nodes EKS

Configurado em `terraform/environments/production/data.tf` via `data "terraform_remote_state"`.

## Outputs

O módulo RDS expõe:
- `db_endpoint` — endpoint de conexão (host:port)
- `db_name` — nome do banco
- `db_secret_arn` — ARN do secret no Secrets Manager
