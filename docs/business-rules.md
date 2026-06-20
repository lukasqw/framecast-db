# Regras de Negócio — framecast-db

Este repo é infraestrutura pura. As "regras" aqui são operacionais e de segurança.

---

## Acesso ao Banco

- Apenas o `framecast-rds-sg` (EKS SG + EKS cluster SG + CIDR da VPC) pode conectar ao RDS na porta 5432.
- Sem acesso público ao banco — `publicly_accessible = false`, sem ingress de `0.0.0.0/0`.
- Conexão via `DATABASE_URL` injetado no deploy a partir do GitHub secret `DB_PASSWORD` + output `rds_address` — nunca credenciais hardcoded no código.
- `framecast-api` e `framecast-worker` compartilham o mesmo `DATABASE_URL` (instância e owner únicos: `framecast`).
- Ferramentas de administração (ex: pgAdmin) devem usar **bastion host ou AWS Systems Manager Session Manager**.

## SSL/TLS

- O parameter group herda `rds.force_ssl = 0` (paridade com LocalStack/dev, onde `sslmode=disable`).
- Em produção, o `DATABASE_URL` do Secret usa `sslmode=require`.
- Endurecer para `force_ssl = 1` é trivial: alterar o `aws_db_parameter_group` em `terraform/modules/rds/main.tf` e garantir `sslmode=require` em todos os consumidores.

## Backup e Retenção

- Backups automatizados habilitados com retenção de **7 dias**.
- `skip_final_snapshot = true` — a instância é **efêmera para a demo do hackathon**. Destruir o repo apaga o banco sem snapshot final. Em produção real, definir `skip_final_snapshot = false`.

## Rotação de Senha

- Sem AWS Secrets Manager e sem rotação automática (conta AWS Academy).
- Rotação é **manual**: atualizar o GitHub secret `DB_PASSWORD` nos repos `framecast-db`, `framecast-api` e `framecast-worker`, re-aplicar o Terraform deste repo (`TF_VAR_db_password`) para alterar a senha master do RDS e redeployar api/worker para reinjetar o novo `DATABASE_URL`.

## Mudanças na Infraestrutura

- Mudanças que causam **replacement** do RDS (ex: `instance_class`, `engine_version`, ou a chave `framecast` do mapa `databases`) destroem e recriam a instância — planejar com janela de manutenção e backup.
- Para renomear a chave do mapa sem destruição: usar `terraform state mv` antes do `apply`.
- Storage só pode crescer, nunca diminuir.

## Schema do Banco

O schema (tabelas `users`, `videos`, `outbox_events`; migrations) é responsabilidade da `framecast-api`, não deste repo. Este repo apenas provê a instância em branco.

- Migrations executadas pela `framecast-api` no boot (GORM AutoMigrate).
- Este repo não tem scripts SQL nem migrations.
- PostgreSQL 16 traz `gen_random_uuid()` built-in — disponível para os models GORM (`DEFAULT gen_random_uuid()`).

## Disaster Recovery

- Single-AZ (custo da demo): **sem failover automático**. Em caso de falha da AZ, recuperação via restore de snapshot.
- DR = restore do último backup automático (retenção 7d) em nova instância.
- Para alta disponibilidade real: habilitar `rds_multi_az = true` (failover automático ~60–120s, endpoint DNS preservado).
