# ADR 002: Usar um código único gerado no celular para não duplicar dados

* **Status:** Aceita | **Data:** 15/11/2026
* **Requisitos relacionados:** RF03, RNF02

## Contexto
Como a internet rural oscila, o celular pode enviar uma entrega para o servidor, mas perder o sinal antes de receber a confirmação. Se isso acontecer, o app tentaria mandar a mesma entrega de novo, duplicando o registro no estoque.

## Decisão
Quando o produtor salva a entrega offline, o próprio app gera um identificador único (`codigo_offline`). No banco central (PostgreSQL), esse campo é marcado como `UNIQUE`. Se o celular enviar o mesmo código duas vezes, o servidor ignora o repetido.

A coluna é declarada como `codigo_offline VARCHAR(50) UNIQUE NOT NULL` em `banco/init.sql`, e a gravação no servidor é feita de forma idempotente: um `INSERT ... ON CONFLICT (codigo_offline) DO NOTHING`. Se o código já existir, nada é criado e a API responde sucesso ao aplicativo, que então remove o item da fila local.

## Consequências
* **Ponto positivo:** Evita entregas duplicadas e erros na contagem do estoque.
* **Ponto de atenção:** A API precisa tratar códigos repetidos sem gerar erro para o aplicativo.

## Alternativas e riscos
* **Alternativa descartada:** usar o `SERIAL` gerado pelo servidor como identificador — inviável, porque o registro nasce no celular, possivelmente sem rede.
* **Consequência negativa:** exige que o aplicativo gere um código realmente único (sem colisão) e mantém um índice único adicional na tabela `entregas`; a API precisa responder sucesso mesmo quando o código já existe.
* **Nota de coerência:** o status `PENDENTE` existe apenas no SQLite do celular. A linha no PostgreSQL só é criada depois da sincronização — por isso o valor padrão de `status_sincronizacao` em `init.sql` é `SINCRONIZADO`.
