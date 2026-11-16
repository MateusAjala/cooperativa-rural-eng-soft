# Requisitos do Sistema — Cooperativa Rural

> Documento alinhado a `README.md`, `banco/init.sql` e `docs/adr/*.md` (sem alteração desses artefatos). O esquema do domínio no PostgreSQL é composto pelas 8 tabelas: `cooperados`, `produtos`, `entregas`, `itens_entrega`, `compradores`, `vendas`, `itens_venda` e `repasses`.

## 1. Requisitos Funcionais (RF)

| ID | Nome | Descrição |
|---|---|---|
| **RF01** | Manter Cadastros Base | Permitir o cadastro e manutenção de `cooperados`, `produtos` e `compradores` (camada de aplicação/API), conforme os campos definidos em `banco/init.sql`. |
| **RF02** | Registrar Entrega Offline no Campo | Permitir que o cooperado registre entregas e itens no app móvel com persistência local em SQLite, sem conectividade, gerando `codigo_offline` único por entrega (ADR 001/002). |
| **RF03** | Sincronizar Entregas em Lote | Permitir o envio em lote das entregas pendentes do SQLite para a API/servidor via HTTPS, persistindo em `entregas` e `itens_entrega` no PostgreSQL 16 com idempotência por `entregas.codigo_offline` (UNIQUE) (ADR 002/003). |
| **RF04** | Corrigir Quantidade/Valor de Entrega na Sede | Permitir que o gestor, na sede, corrija valores de entrega quando houver diferença (ex.: conferência na balança) antes do fechamento do pagamento do mês, conforme decisão de escopo do `README.md`, refletindo os ajustes nas regras/estoque da aplicação. |
| **RF05** | Consultar Estoque Central | Permitir a consulta do estoque central com base em `produtos.saldo_estoque` e nas movimentações registradas (entregas e vendas) pela aplicação. |
| **RF06** | Registrar Venda Regional | Permitir o registro de vendas para `compradores`, com `vendas`, `itens_venda` e `valor_total`, respeitando a disponibilidade de estoque apurada pela aplicação. |
| **RF07** | Calcular e Fechar Repasse Mensal | Calcular e registrar o repasse mensal por `cooperado_id` e `periodo_referencia` (`AAAA-MM`) na tabela `repasses`, apurando `valor_bruto`, `taxa_cooperativa`, `valor_liquido` e `status_pagamento`. |
| **RF08** | Registrar Pagamento de Repasse e Emitir Extrato | Permitir atualizar/registrar a situação de pagamento do repasse (`repasses.status_pagamento`) e emitir extrato ao cooperado com base nos registros do período. |

## 2. Requisitos Não Funcionais (RNF) — Infraestrutura

| ID | Categoria | Descrição |
|---|---|---|
| **RNF01** | Disponibilidade/Offline | Operação 100% offline no campo com banco local SQLite no aplicativo móvel (ADR 001). |
| **RNF02** | Desempenho/Confiabilidade | Sincronização em lote (ex.: até 50 registros em até 30s, conforme meta do projeto) com tratamento idempotente de duplicidades por `codigo_offline` e processamento transacional no servidor (ADR 002/003). |
| **RNF03** | Segurança | Comunicação via HTTPS/TLS entre cliente e API; controle de acesso por perfis *Cooperado*, *Gestor* e *Administrador* na camada da API (conforme `README.md` e ADR 003). |
| **RNF04** | Backup/Recuperação | Backup diário automatizado via `pg_dump` executado fora do container, com retenção de 30 dias (ADR 003). |

## 3. Matriz de Rastreabilidade

| RF | Caso de Uso | Classes/Entidades de Domínio (alinhadas ao `init.sql`) | Tabelas (`banco/init.sql`) |
|---|---|---|---|
| **RF01** | UC01 - Manter Cadastros Base | `cooperados`, `produtos`, `compradores` | `cooperados`, `produtos`, `compradores` |
| **RF02** | UC02 - Registrar Entrega no Campo | `cooperados`, `produtos`, `entregas`, `itens_entrega` | `entregas`, `itens_entrega`, `cooperados`, `produtos` |
| **RF03** | UC03 - Sincronizar Entregas em Lote | `entregas`, `itens_entrega`, `cooperados`, `produtos` | `entregas`, `itens_entrega`, `cooperados`, `produtos` |
| **RF04** | UC04 - Corrigir Quantidade de Entrega na Sede | `entregas`, `itens_entrega`, `produtos` | `entregas`, `itens_entrega`, `produtos` |
| **RF05** | UC05 - Consultar Estoque Central | `produtos`, `entregas`, `itens_entrega`, `vendas`, `itens_venda` | `produtos`, `entregas`, `itens_entrega`, `vendas`, `itens_venda` |
| **RF06** | UC06 - Registrar Venda Regional | `compradores`, `vendas`, `itens_venda`, `produtos` | `compradores`, `vendas`, `itens_venda`, `produtos` |
| **RF07** | UC07 - Fechar Repasse Mensal | `cooperados`, `entregas`, `itens_entrega`, `repasses` | `cooperados`, `entregas`, `itens_entrega`, `repasses` |
| **RF08** | UC08 - Registrar Pagamento de Repasse e Emitir Extrato | `repasses`, `cooperados` | `repasses`, `cooperados` |
