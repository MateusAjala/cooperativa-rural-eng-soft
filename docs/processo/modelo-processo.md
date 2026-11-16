# Modelo de Processo de Desenvolvimento

## 1. Escolha e Justificativa: Modelo Incremental

O projeto **Tema 4 – Estoque e Vendas de uma Cooperativa Rural** adota o **Modelo Incremental** de desenvolvimento, em coerência com as decisões já registradas no repositório (`README.md`, `banco/init.sql` e ADRs em `docs/adr/`).

**Justificativas:**
- **Mitigação de risco offline-first (SQLite + `codigo_offline`)**: conforme ADR 001 e ADR 002, o registro no campo ocorre offline no SQLite e a sincronização depende de identificador único (`entregas.codigo_offline`, `UNIQUE` no PostgreSQL) para evitar duplicidade. Entregar esse núcleo cedo reduz risco de inconsistência.
- **Validação antecipada campo vs. sede**: permite validar separadamente o fluxo do app móvel (offline, fila pendente no SQLite) e o fluxo da sede/web + API (sincronização via HTTPS, persistência no PostgreSQL 16), ajustando regras antes da consolidação.
- **Modularidade e aderência ao escopo definido**: o esquema do domínio já está consolidado em 8 tabelas (`cooperados`, `produtos`, `entregas`, `itens_entrega`, `compradores`, `vendas`, `itens_venda`, `repasses`) e as decisões de infraestrutura/segurança (HTTPS, lote, backup `pg_dump`) orientam incrementos evolutivos.

## 2. Incrementos Aplicados

### Incremento 1 — Núcleo de Dados e Docker
**Objetivo:** estabelecer a base estrutural e de infraestrutura do sistema.

**Escopo principal (alinhado ao repositório):**
- Disponibilização do PostgreSQL 16 via Docker Compose e execução automática de `banco/init.sql` na primeira inicialização (volume vazio).
- Criação das 8 tabelas do domínio: `cooperados`, `produtos`, `entregas`, `itens_entrega`, `compradores`, `vendas`, `itens_venda`, `repasses`.
- Base para cadastros operacionais de cooperados, produtos e compradores (camada de aplicação/API).
- Definição de escopo de acesso: login e perfis (*Cooperado*, *Gestor*, *Administrador*) tratados na camada da API (conforme `README.md`).

**Resultado esperado:** ambiente reprodutível e esquema central consistente para os fluxos de campo e sede.

### Incremento 2 — Operação Offline-First e Sincronização em Lote
**Objetivo:** viabilizar o registro no campo sem conectividade e a consolidação segura na sede.

**Escopo principal (alinhado às ADRs 001, 002 e 003):**
- Registro de entregas no app móvel com persistência local em SQLite, funcionando 100% offline (RNF01), com status `PENDENTE` apenas no SQLite local (nota ADR 002).
- Geração de `codigo_offline` no app e sincronização idempotente no servidor (`entregas.codigo_offline` UNIQUE; gravação tratada sem duplicar registros).
- Envio em lote das entregas pendentes via HTTPS (RNF02/RNF03), com confirmação do servidor para atualização da fila local.
- Atualização de estoque/produtos conforme regras da aplicação e possibilidade de correção de valores pelo gestor antes do fechamento do pagamento do mês (decisão de escopo do `README.md`).

**Resultado esperado:** fluxo ponta a ponta de entregas (campo → sincronização → base central) com proteção contra duplicidade.

### Incremento 3 — Vendas Regionais e Repasse Mensal
**Objetivo:** completar o ciclo operacional e financeiro da cooperativa.

**Escopo principal (alinhado ao `init.sql` e ADR 003):**
- Registro de vendas regionais (`vendas`, `itens_venda`) associadas a `compradores` e `produtos`, com controle de valores e movimentação de estoque pela aplicação.
- Cálculo e registro de repasses mensais (`repasses`) por cooperado e período de referência (`periodo_referencia`, formato `AAAA-MM`), com `valor_bruto`, `taxa_cooperativa`, `valor_liquido` e `status_pagamento`.
- Acompanhamento/registro do pagamento do repasse e emissão de extrato pela camada de aplicação.
- Consolidação de rotinas operacionais de segurança e confiabilidade: comunicação HTTPS/TLS, controle de acesso por perfis na API e backup diário via `pg_dump` fora do container com retenção de 30 dias (RNF03, RNF04).

**Resultado esperado:** suporte ao ciclo completo de recebimento, comercialização e repasse financeiro aos cooperados sobre a base de dados definida no projeto.
