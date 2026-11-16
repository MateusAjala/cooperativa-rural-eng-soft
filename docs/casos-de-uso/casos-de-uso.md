# Especificação de Casos de Uso — Cooperativa Rural

> Documento alinhado a `README.md`, `banco/init.sql` e `docs/adr/*.md`. O login e os perfis (*Cooperado*, *Gestor*, *Administrador*) são tratados na camada da API (conforme `README.md`); o status `PENDENTE` de sincronização existe apenas no SQLite local do app (ADR 002).

## UC02 - Registrar Entrega no Campo

- **Atores:** Cooperado
- **Requisitos Relacionados:** RF02, RNF01
- **Pré-condições:**
  - O cooperado está autenticado no aplicativo móvel (controle na API).
  - O app possui base local SQLite operacional com dados necessários para o registro (ex.: identificação do cooperado e produtos).
  - Pode não haver conectividade com a sede.

- **Fluxo Principal:**
  1. O cooperado seleciona a opção de registrar nova entrega.
  2. O app exibe o formulário de entrega (cooperado e data/hora da entrega).
  3. O cooperado informa os itens da entrega (produto e quantidade).
  4. O app gera um `codigo_offline` único para a entrega.
  5. O cooperado confirma o registro.
  6. O app persiste a entrega e seus itens no SQLite local, marcando a entrega como pendente de sincronização (`PENDENTE`, apenas no SQLite).
  7. O app apresenta confirmação do registro.

- **Fluxos Alternativos/Exceção:**
  - **A1 - Dados obrigatórios ausentes ou inválidos:** O app valida os campos (ex.: quantidade > 0) e solicita correção antes de salvar.
  - **A2 - Produto/cooperado não disponível localmente:** O app impede a conclusão do registro e orienta atualização/sincronização de cadastros quando houver conexão.
  - **E1 - Falha de gravação local:** O app informa o erro e não confirma o registro.

- **Pós-condições:**
  - A entrega e seus itens ficam armazenados localmente com `codigo_offline` único, aguardando sincronização.

## UC03 - Sincronizar Entregas em Lote

- **Atores:** Cooperado (ação no app) / API Backend (processamento)
- **Requisitos Relacionados:** RF03, RNF02, RNF03
- **Pré-condições:**
  - Existem entregas pendentes de sincronização no SQLite local.
  - Há conectividade com a API via HTTPS/TLS.
  - O cooperado está autenticado.

- **Fluxo Principal:**
  1. O cooperado solicita a sincronização das entregas pendentes.
  2. O app seleciona um lote de entregas pendentes (até 50 registros, conforme meta RNF02).
  3. O app envia o lote para a API via HTTPS.
  4. A API processa o lote no PostgreSQL 16 em uma única transação (ADR 003).
  5. Para cada entrega do lote, a API tenta persistir em `entregas` e `itens_entrega` de forma idempotente usando `codigo_offline` (UNIQUE), conforme ADR 002 (ex.: ignorar conflito quando o código já existir).
  6. A API retorna o resultado do processamento (sucesso/rejeições por item, quando aplicável), tratando reenvios sem duplicar dados.
  7. Após confirmação do servidor, o app atualiza localmente os registros processados (remoção da fila/marcação como sincronizada no SQLite).

- **Fluxos Alternativos/Exceção:**
  - **A1 - `codigo_offline` já existente no servidor (reenvio):** A API não cria duplicidade e responde de forma idempotente; o app considera o item sincronizado.
  - **A2 - Rejeição de item do lote:** A API informa o resultado item a item; os itens rejeitados permanecem para correção/reenvio conforme regra da aplicação.
  - **E1 - Falha de comunicação/timeout:** Sem confirmação, o app mantém os registros como pendentes para nova tentativa.
  - **E2 - Falha transacional no servidor:** O lote não é confirmado parcialmente de forma inconsistente; o app mantém pendências para nova tentativa.

- **Pós-condições:**
  - Entregas aceitas ficam persistidas no PostgreSQL (`entregas.status_sincronizacao` conforme esquema/ADR; no `init.sql` o padrão é `SINCRONIZADO`).
  - Reenvios do mesmo `codigo_offline` não geram duplicidade.

## UC04 - Corrigir Quantidade de Entrega na Sede

- **Atores:** Gestor
- **Requisitos Relacionados:** RF04, RF05
- **Pré-condições:**
  - O gestor está autenticado no sistema web (controle na API).
  - Existem entregas/itens sincronizados que podem ser ajustados antes do fechamento do pagamento do mês (decisão de escopo do `README.md`).

- **Fluxo Principal:**
  1. O gestor localiza a entrega e os itens a serem verificados.
  2. O sistema exibe os dados registrados (incluindo `itens_entrega.quantidade` e produto associado).
  3. O gestor informa a correção necessária (ex.: diferença apurada na balança na chegada à sede).
  4. O gestor confirma a correção.
  5. O sistema atualiza os registros pertinentes e recalcula impactos necessários (ex.: `produtos.saldo_estoque` e base para repasse), conforme regras da aplicação.
  6. O sistema apresenta confirmação da atualização.

- **Fluxos Alternativos/Exceção:**
  - **A1 - Sem divergência:** O gestor conclui a verificação sem alterações.
  - **A2 - Correção não permitida (ex.: período/repasse já fechado):** O sistema bloqueia a alteração e informa o motivo.
  - **E1 - Valor inválido (ex.: quantidade <= 0, violando regra do banco):** O sistema rejeita a entrada e solicita correção.

- **Pós-condições:**
  - Os dados de entrega/estoque refletem a correção realizada, quando aplicável.
  - O fechamento do repasse mensal considera os valores vigentes definidos pela aplicação.

## UC06 - Registrar Venda Regional

- **Atores:** Gestor (ou Administrador, conforme perfil na API)
- **Requisitos Relacionados:** RF06, RF05
- **Pré-condições:**
  - O usuário está autenticado no sistema web (controle na API).
  - Existem registros em `compradores` e `produtos`.
  - Há disponibilidade de estoque suficiente para os itens da venda (validação na aplicação).

- **Fluxo Principal:**
  1. O usuário seleciona a opção de registrar venda regional.
  2. O sistema solicita os dados da venda (`comprador_id`, data, itens com `produto_id`, `quantidade`, `preco_unitario`) e calcula/apura `valor_total`.
  3. O usuário informa os dados e confirma.
  4. O sistema valida a disponibilidade de estoque e a consistência dos valores (**include: Validar Estoque Disponível**).
  5. O sistema persiste `vendas` e `itens_venda` no PostgreSQL 16.
  6. O sistema atualiza o saldo de estoque (`produtos.saldo_estoque`) conforme regras da aplicação e apresenta confirmação.

- **Fluxos Alternativos/Exceção:**
  - **A1 - Estoque insuficiente:** O sistema impede a confirmação e solicita ajuste de quantidade/itens.
  - **A2 - Dados inválidos (ex.: quantidade <= 0, comprador/produto inexistente):** O sistema rejeita a operação e solicita correção.
  - **E1 - Falha de persistência:** A operação é cancelada sem registrar venda parcial inconsistente.

- **Pós-condições:**
  - A venda e seus itens ficam registrados em `vendas` e `itens_venda`.
  - O estoque central é atualizado de acordo com a venda.

## UC07 - Fechar Repasse Mensal

- **Atores:** Gestor
- **Requisitos Relacionados:** RF07, RF04, RF03
- **Pré-condições:**
  - O gestor está autenticado no sistema web (controle na API).
  - Existem entregas sincronizadas no período e dados necessários para apuração (incluindo correções prévias, se houver).
  - Regras/percentuais de taxa da cooperativa estão definidos na aplicação.

- **Fluxo Principal:**
  1. O gestor seleciona a opção de fechamento de repasse mensal.
  2. O gestor informa `cooperado_id` e `periodo_referencia` (`AAAA-MM`).
  3. O sistema verifica se já existe repasse para o mesmo cooperado e período (regra da aplicação, considerando `repasses`).
  4. O sistema apura as entregas/itens elegíveis do período e calcula `valor_bruto`, `taxa_cooperativa` e `valor_liquido`.
  5. O sistema apresenta o resumo do cálculo para confirmação.
  6. O gestor confirma o fechamento.
  7. O sistema registra o repasse em `repasses` com `status_pagamento` conforme regra definida (ex.: `PENDENTE`, default do banco).

- **Fluxos Alternativos/Exceção:**
  - **A1 - Repasse já existente para o período:** O sistema bloqueia novo fechamento duplicado e exibe o registro existente.
  - **A2 - Não há base elegível para o período:** O sistema informa a situação e não gera o repasse.
  - **E1 - Falha no cálculo/persistência:** A operação é cancelada sem gerar registro inconsistente.

- **Pós-condições:**
  - Fica registrado em `repasses` o resultado do fechamento para o cooperado e período informados.
  - Os valores ficam disponíveis para acompanhamento de pagamento e emissão de extrato (RF08).
