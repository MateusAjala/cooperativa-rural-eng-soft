# Tema 4 – Estoque e Vendas de uma Cooperativa Rural

Projeto Final de **Engenharia de Software I**. Sistema para registro de entregas no campo (offline-first com SQLite e sincronização via HTTPS), controle de estoque central, vendas regionais e cálculo de repasse financeiro aos cooperados.

## Integrantes
- **Mateus Ajala**
- **Henrique Vidigal**

## Entregáveis
- **Processo e Requisitos:** [`docs/processo/modelo-processo.md`](docs/processo/modelo-processo.md) · [`docs/requisitos/requisitos.md`](docs/requisitos/requisitos.md) · [`docs/casos-de-uso/casos-de-uso.md`](docs/casos-de-uso/casos-de-uso.md)
- **Decisões de Arquitetura (ADRs):** [`001-sqlite`](docs/adr/001-arquitetura-offline-first-sqlite.md) · [`002-codigo-offline`](docs/adr/002-controle-duplicidade-codigo-offline.md) · [`003-lote-e-backup`](docs/adr/003-sincronizacao-em-lote-e-backup.md)
- **Diagramas ([`diagramas/`](diagramas/)):** Casos de Uso (`casos-de-uso`), Classes (`classes`), Sequência (`sequencia-sincronizacao`, `sequencia-repasse`), Implantação (`implantacao`) e Esquema do Banco (`esquema-banco`).
- **Banco e Infraestrutura:** [`banco/init.sql`](banco/init.sql) · [`docker-compose.yml`](docker-compose.yml)

## Como Executar o Banco (Docker)

**Pré-requisito:** Docker e Docker Compose instalados.

```bash
# 1. Clonar e entrar no projeto
git clone https://github.com/MateusAjala/cooperativa-rural-eng-soft.git
cd cooperativa-rural-eng-soft

# 2. Subir o PostgreSQL 16 (executa o init.sql automaticamente na 1ª vez)
docker compose up -d

# 3. Validar as 8 tabelas criadas
docker exec -it cooperativa_db psql -U postgres -d cooperativa -c "\dt"

# 4. Parar (ou 'down -v' para apagar o volume e recriar do zero)
docker compose down
```

- **Conexão:** `localhost:5432` · banco `cooperativa` · usuário `postgres` · senha `123` (ambiente local).
- *O `init.sql` só é executado na primeira inicialização (volume vazio). Para reexecutá-lo: `docker compose down -v` e `docker compose up -d`.*

## Decisões de Escopo
- **Login e Perfis (RNF03):** O banco guarda apenas as 8 tabelas do domínio (cooperados, produtos, entregas, itens_entrega, compradores, vendas, itens_venda e repasses). O login e as permissões de acesso (*Cooperado*, *Gestor* e *Administrador*) ficam na camada da API.
- **Conferência de Peso:** O valor digitado pelo produtor no celular entra direto no estoque. Se houver diferença na balança quando a carga chegar na sede, o gestor corrige o valor no sistema antes de fechar o pagamento do mês.
