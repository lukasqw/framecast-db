# Regras de Negócio — oficina-tech-db

Este repo é infraestrutura pura. As "regras" aqui são operacionais e de segurança.

---

## Acesso ao Banco

- Apenas o security group dos **nodes EKS** pode conectar ao RDS (porta 5432)
- Sem acesso público ao banco — nenhuma regra de ingress de `0.0.0.0/0`
- Conexão via **connection string do Secrets Manager** — nunca credenciais hardcoded
- Ferramentas de administração (ex: pgAdmin) devem usar **bastion host ou AWS Systems Manager Session Manager**

## Backup e Retenção

- Backups automatizados habilitados com retenção de **7 dias**
- Backup final obrigatório antes de destruir a instância (`skip_final_snapshot = false` em produção)
- Janela de backup: horário de menor uso (madrugada, UTC)

## Mudanças na Infraestrutura

- Mudanças que causam **replacement** do RDS (ex: mudar `instance_class`, `engine_version`) devem ser planejadas com janela de manutenção
- `apply_immediately = false` em produção — mudanças aplicadas na janela de manutenção
- Qualquer mudança de `storage` só pode crescer, nunca diminuir

## Schema do Banco

O schema (tabelas, migrations) é responsabilidade do repo `oficina-tech`, não deste repo. Este repo apenas provê a instância em branco.

- Migrations são executadas pelo backend Go na inicialização (via GORM AutoMigrate)
- Este repo não tem scripts SQL nem migrations

## Disaster Recovery

- Em caso de falha da AZ primária: failover automático para standby (se Multi-AZ habilitado)
- Tempo estimado de failover: 60-120 segundos
- Connection string não muda após failover (RDS mantém mesmo endpoint DNS)
