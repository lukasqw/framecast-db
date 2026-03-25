# Oficina Tech - Database Infrastructure

Infraestrutura de banco de dados PostgreSQL para o projeto Oficina Tech, provisionada e gerenciada através de Terraform na AWS.

## Descrição

Este repositório contém a infraestrutura como código (IaC) para provisionar e gerenciar o banco de dados PostgreSQL RDS utilizado pelo sistema Oficina Tech. A infraestrutura é totalmente automatizada usando Terraform e inclui configurações de segurança, backup, monitoramento e integração com o cluster EKS.

O banco de dados é provisionado na AWS RDS com PostgreSQL 16, configurado para alta disponibilidade através de Multi-AZ deployment, com backups automatizados e monitoramento via CloudWatch.

## Estrutura de Pastas

```
oficina-tech-db/
├── .github/
│   └── workflows/          # Pipelines CI/CD
│       ├── ci.yml          # Validação do Terraform
│       └── deploy.yml      # Deploy da infraestrutura
├── docs/
│   └── database-component-diagram.puml  # Diagrama de componentes
├── terraform/
│   ├── environments/       # Configurações por ambiente
│   │   └── production/     # Ambiente de produção
│   │       ├── backend.tf      # Configuração do backend S3
│   │       ├── data.tf         # Data sources (VPC, subnets)
│   │       ├── locals.tf       # Variáveis locais
│   │       ├── main.tf         # Recursos principais
│   │       ├── outputs.tf      # Outputs do Terraform
│   │       ├── provider.tf     # Configuração do provider AWS
│   │       └── variables.tf    # Variáveis de entrada
│   └── modules/
│       └── rds/            # Módulo RDS PostgreSQL
│           ├── main.tf         # Recursos do RDS
│           ├── outputs.tf      # Outputs do módulo
│           └── variables.tf    # Variáveis do módulo
├── .gitignore
├── Makefile                # Comandos para gerenciar Terraform
└── README.md
```

## Funcionalidades

### Infraestrutura de Banco de Dados

- **RDS PostgreSQL 16**: Instância gerenciada do PostgreSQL na AWS
- **Instância db.t3.micro**: Configuração otimizada para custos
- **Storage**: 20GB gp2 com auto-scaling configurável
- **Multi-AZ Deployment**: Suporte para alta disponibilidade (configurável)

### Segurança

- **Security Groups**: Controle de acesso granular
  - Acesso do cluster EKS (security group do EKS)
  - Acesso dos nodes do cluster (cluster security group)
  - Acesso da VPC (permite conexões dos pods)
- **Subnet Groups**: Deployment em múltiplas zonas de disponibilidade
- **Parameter Groups**: Configurações customizadas do PostgreSQL
- **SSL**: Configurável (desabilitado em desenvolvimento)

### Backup e Recuperação

- **Backups Automatizados**: Retenção configurável (padrão: 1 dia)
- **Snapshots Manuais**: Suporte para snapshots sob demanda
- **Point-in-Time Recovery**: Recuperação para qualquer momento dentro do período de retenção
- **Final Snapshot**: Snapshot automático antes da destruição (configurável)

### Monitoramento

- **CloudWatch Logs**: Logs do PostgreSQL exportados automaticamente
- **Performance Insights**: Monitoramento de performance habilitado
- **Métricas**: CPU, conexões, storage, IOPS
- **Alertas**: Integração com CloudWatch para alertas customizados

### Integração

- **EKS Cluster**: Conectividade configurada com o cluster Kubernetes
- **Lambda Functions**: Suporte para funções Lambda (ex: CPF Auth)
- **Remote State**: Importa recursos do projeto oficina-tech-infra
- **VPC Integration**: Deployment dentro da VPC existente

### CI/CD

- **Validação Automática**: Terraform format e validate em PRs
- **Deploy Automatizado**: Deploy automático na branch main
- **Post-Deploy Checks**: Verificação do status do RDS após deploy
- **GitHub Actions**: Pipelines completos de CI/CD

## Tecnologias Usadas

- **Terraform** (v1.7.0): Infraestrutura como código
- **AWS RDS**: Serviço de banco de dados gerenciado
- **PostgreSQL** (v16): Sistema de gerenciamento de banco de dados
- **AWS CloudWatch**: Monitoramento e logs
- **AWS S3**: Backend para Terraform state
- **GitHub Actions**: CI/CD e automação
- **PlantUML**: Documentação de arquitetura

### Recursos AWS

- AWS RDS (PostgreSQL)
- AWS VPC
- AWS Security Groups
- AWS Subnet Groups
- AWS Parameter Groups
- AWS CloudWatch
- AWS S3 (snapshots e state)

## Como Rodar o Projeto

### Pré-requisitos

- [Terraform](https://www.terraform.io/downloads) >= 1.7.0
- [AWS CLI](https://aws.amazon.com/cli/) configurado
- Credenciais AWS com permissões adequadas
- Acesso ao remote state do projeto `oficina-tech-infra`
- Make (opcional, para usar os comandos do Makefile)

### Configuração Inicial

1. Clone o repositório:

```bash
git clone <repository-url>
cd oficina-tech-db
```

2. Configure as credenciais AWS:

```bash
aws configure
```

3. Crie um arquivo de variáveis (não commitado):

```bash
# terraform/environments/production/terraform.tfvars
db_password = "sua-senha-segura"
```

### Usando Makefile

O projeto inclui um Makefile para facilitar operações comuns:

```bash
# Inicializar Terraform
make init

# Visualizar mudanças planejadas
make plan

# Aplicar mudanças
make apply

# Destruir infraestrutura
make destroy

# Formatar código Terraform
make fmt

# Validar configuração
make validate
```

### Usando Terraform Diretamente

```bash
# Navegar para o ambiente
cd terraform/environments/production

# Inicializar
terraform init

# Planejar mudanças
terraform plan

# Aplicar mudanças
terraform apply

# Ver outputs
terraform output
```

### Variáveis de Ambiente

Para diferentes ambientes, use a variável `ENV`:

```bash
# Produção (padrão)
make plan ENV=production

# Outros ambientes (quando configurados)
make plan ENV=staging
```

### Outputs Importantes

Após o deploy, você pode obter informações importantes:

```bash
terraform output rds_endpoint        # Endpoint do banco de dados
terraform output rds_port            # Porta do banco de dados
terraform output rds_database_name   # Nome do banco de dados
terraform output rds_username        # Usuário do banco de dados
```

### Conectando ao Banco de Dados

```bash
# Obter endpoint
RDS_ENDPOINT=$(terraform output -raw rds_endpoint)

# Conectar via psql (de dentro da VPC ou através de bastion)
psql -h $RDS_ENDPOINT -U postgres -d eks_oficina_tech
```

### CI/CD via GitHub Actions

O projeto possui pipelines automatizados:

- **Pull Requests**: Validação automática do código Terraform
- **Push para main**: Deploy automático da infraestrutura
- **Manual Trigger**: Deploy sob demanda via workflow_dispatch

### Secrets Necessários no GitHub

Configure os seguintes secrets no repositório:

- `AWS_ACCESS_KEY_ID`: Access key da AWS
- `AWS_SECRET_ACCESS_KEY`: Secret key da AWS
- `AWS_SESSION_TOKEN`: Session token (se aplicável)
- `DB_PASSWORD`: Senha do banco de dados

## Manutenção

### Backups

Os backups são automáticos, mas você pode criar snapshots manuais:

```bash
aws rds create-db-snapshot \
  --db-instance-identifier eks-oficina-tech-db \
  --db-snapshot-identifier manual-snapshot-$(date +%Y%m%d)
```

### Monitoramento

Acesse o CloudWatch para visualizar métricas e logs:

```bash
aws rds describe-db-instances \
  --db-instance-identifier eks-oficina-tech-db \
  --query 'DBInstances[0].[DBInstanceStatus,Engine,EngineVersion]'
```

### Atualizações

Para atualizar a versão do PostgreSQL ou configurações:

1. Modifique as variáveis em `variables.tf`
2. Execute `terraform plan` para revisar mudanças
3. Execute `terraform apply` para aplicar

## Segurança

- Nunca commite arquivos `.tfvars` com senhas
- Use AWS Secrets Manager para senhas em produção
- Habilite SSL em produção (`rds.force_ssl = 1`)
- Configure deletion protection em produção
- Revise security groups regularmente

## Licença

Este projeto faz parte do sistema Oficina Tech.
