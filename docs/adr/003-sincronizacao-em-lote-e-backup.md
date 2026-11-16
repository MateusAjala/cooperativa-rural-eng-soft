# ADR 003: Envio em lote via HTTPS e backup diário do banco

* **Status:** Aceita | **Data:** 15/11/2026
* **Requisitos relacionados:** RF03, RNF02, RNF03, RNF04

## Contexto
Quando o produtor chega em um local com internet, pode ter várias entregas acumuladas no celular. Enviar uma por uma deixaria a sincronização lenta (RNF02). Além disso, os dados de estoque e pagamentos precisam estar seguros (RNF03 e RNF04).

## Decisão
1. Enviar todas as entregas pendentes juntas em um único pacote (lote) usando **HTTPS**, mudando o status no celular para `SINCRONIZADO` após o servidor confirmar.
2. Rodar o banco PostgreSQL no Docker com uma rotina automática de backup diário (`pg_dump`) guardada por 30 dias.

## Consequências da sincronização
* **Ponto positivo:** um lote de até 50 registros é enviado dentro do limite de 30 segundos (RNF02), com poucos round-trips, e o tráfego vai protegido por HTTPS/TLS (RNF03).
* **Ponto de atenção:** o servidor precisa salvar o pacote todo dentro de uma única transação para não salvar pela metade. Se um item for rejeitado, a API deve responder item a item, e não apenas sucesso/erro do lote.

## Consequências do backup
* **Ponto positivo:** o `pg_dump` roda fora do container, então o arquivo sobrevive a um `docker compose down -v` e protege contra erro humano e corrupção do volume (RNF04).
* **Ponto de atenção:** o backup é diário, portanto há perda potencial de até 24 horas de dados; o procedimento de restauração precisa ser testado, não apenas documentado.

## Alternativas e riscos
* **Alternativa descartada:** backup apenas do volume Docker — não protege contra remoção do volume nem contra corrupção dos arquivos.
* **Alternativa descartada:** envio registro a registro em tempo real — muitos round-trips, inviável em rede instável.
