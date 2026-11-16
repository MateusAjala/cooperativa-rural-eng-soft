# ADR 001: Salvar entregas localmente no celular com SQLite

* **Status:** Aceita | **Data:** 15/11/2026
* **Requisitos relacionados:** RF02, RF03, RNF01, RNF03

## Contexto
No campo, os produtores muitas vezes ficam sem sinal de internet. Se o aplicativo precisasse de conexão na hora para salvar, o produtor não conseguiria registrar a entrega (violando o RNF01).

## Decisão
Usar um banco de dados local (**SQLite**) dentro do próprio aplicativo do celular. Quando o produtor clica em salvar, os dados ficam gravados no aparelho com status `PENDENTE`.

## Consequências
* **Ponto positivo:** O aplicativo funciona 100% offline no campo (atende ao RNF01) e salva na hora.
* **Ponto de atenção:** O aplicativo precisa guardar uma fila de envios pendentes para sincronizar depois.

## Alternativas e riscos
* **Alternativa descartada:** aplicativo online-only, gravando direto no servidor — mais simples, mas violaria o RNF01.
* **Consequência negativa:** passam a existir dois esquemas de dados (SQLite no celular e PostgreSQL no servidor), e a consistência é eventual: o servidor só conhece a entrega depois da sincronização.
