CREATE TABLE cooperados (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    cpf_cnpj VARCHAR(18) UNIQUE NOT NULL,
    propriedade VARCHAR(150) NOT NULL,
    telefone VARCHAR(20),
    ativo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE produtos (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    unidade_medida VARCHAR(20) NOT NULL,
    preco_referencia DECIMAL(10, 2) NOT NULL,
    saldo_estoque DECIMAL(12, 3) NOT NULL DEFAULT 0
);

CREATE TABLE entregas (
    id SERIAL PRIMARY KEY,
    codigo_offline VARCHAR(50) UNIQUE NOT NULL, -- ID gerado no app para nao duplicar ao sincronizar
    cooperado_id INT NOT NULL REFERENCES cooperados(id),
    data_entrega TIMESTAMP NOT NULL,
    status_sincronizacao VARCHAR(20) NOT NULL DEFAULT 'SINCRONIZADO'
);

CREATE TABLE itens_entrega (
    id SERIAL PRIMARY KEY,
    entrega_id INT NOT NULL REFERENCES entregas(id) ON DELETE CASCADE,
    produto_id INT NOT NULL REFERENCES produtos(id),
    quantidade DECIMAL(12, 3) NOT NULL CHECK (quantidade > 0)
);

CREATE TABLE compradores (
    id SERIAL PRIMARY KEY,
    razao_social VARCHAR(150) NOT NULL,
    cnpj VARCHAR(18) UNIQUE NOT NULL,
    cidade VARCHAR(100) NOT NULL
);

CREATE TABLE vendas (
    id SERIAL PRIMARY KEY,
    comprador_id INT NOT NULL REFERENCES compradores(id),
    data_venda TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valor_total DECIMAL(12, 2) NOT NULL
);

CREATE TABLE itens_venda (
    id SERIAL PRIMARY KEY,
    venda_id INT NOT NULL REFERENCES vendas(id) ON DELETE CASCADE,
    produto_id INT NOT NULL REFERENCES produtos(id),
    quantidade DECIMAL(12, 3) NOT NULL CHECK (quantidade > 0),
    preco_unitario DECIMAL(10, 2) NOT NULL
);

CREATE TABLE repasses (
    id SERIAL PRIMARY KEY,
    cooperado_id INT NOT NULL REFERENCES cooperados(id),
    periodo_referencia VARCHAR(7) NOT NULL,
    valor_bruto DECIMAL(12, 2) NOT NULL,
    taxa_cooperativa DECIMAL(12, 2) NOT NULL,
    valor_liquido DECIMAL(12, 2) NOT NULL,
    status_pagamento VARCHAR(20) NOT NULL DEFAULT 'PENDENTE'
);