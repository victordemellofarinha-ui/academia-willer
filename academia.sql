CREATE TABLE alunos (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    cpf VARCHAR(11) UNIQUE NOT NULL,
    telefone VARCHAR(20) NOT NULL,
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE planos (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) UNIQUE NOT NULL,
    valor_mensal_base NUMERIC(10,2) NOT NULL CHECK (valor_mensal_base > 0)
);

CREATE TABLE modalidades (
    id SERIAL PRIMARY KEY,
    plano_id INT NOT NULL REFERENCES planos(id),
    nome VARCHAR(100) NOT NULL,
    sala VARCHAR(50) NOT NULL,
    capacidade_maxima INT NOT NULL CHECK (capacidade_maxima > 0),
    disponivel BOOLEAN DEFAULT TRUE
);

CREATE TABLE matriculas (
    id SERIAL PRIMARY KEY,
    aluno_id INT NOT NULL REFERENCES alunos(id),
    data_inicio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'Ativa'
    CHECK (status IN ('Ativa', 'Cancelada', 'Trancada'))
);

CREATE TABLE itens_matricula (
    id SERIAL PRIMARY KEY,
    matricula_id INT NOT NULL REFERENCES matriculas(id),
    modalidade_id INT NOT NULL REFERENCES modalidades(id),
    duracao_meses INT NOT NULL CHECK (duracao_meses > 0),
    valor_mensal_aplicado NUMERIC(10,2) NOT NULL CHECK (valor_mensal_aplicado > 0),
    taxa_adesao NUMERIC(10,2) DEFAULT 0.00 CHECK (taxa_adesao >= 0)
);



INSERT INTO planos (nome, valor_mensal_base)
VALUES
('VIP Premium', 200.00),
('Fitness Standard', 120.00),
('Basic Fit', 80.00);


INSERT INTO modalidades
(plano_id, nome, sala, capacidade_maxima, disponivel)
VALUES
(1, 'Crossfit Pro', 'Arena 01', 20, TRUE),
(2, 'Pilates Avançado', 'Studio 02', 15, TRUE),
(3, 'Musculação Livre', 'Arena 03', 25, TRUE);


INSERT INTO alunos (nome, email, cpf, telefone)
VALUES
('João Silva', 'joao@email.com', '12345678901', '48999991111'),
('Maria Santos', 'maria@email.com', '23456789012', '48999992222'),
('Pedro Oliveira', 'pedro@email.com', '34567890123', '48999993333');


INSERT INTO matriculas (aluno_id, status)
VALUES
(1, 'Ativa'),
(2, 'Ativa'),
(3, 'Cancelada'),
(1, 'Ativa');


INSERT INTO itens_matricula
(matricula_id, modalidade_id, duracao_meses,
 valor_mensal_aplicado, taxa_adesao)
VALUES
(1, 1, 12, 200.00, 100.00),
(2, 2, 6, 120.00, 50.00),
(3, 3, 3, 80.00, 0.00),
(4, 1, 12, 220.00, 100.00);


CREATE VIEW vw_modalidades_custo_estimado AS
SELECT
    modalidades.nome AS modalidade,
    modalidades.sala,
    planos.nome AS plano,
    planos.valor_mensal_base * 1.10 AS valor_ajustado
FROM modalidades
JOIN planos
ON modalidades.plano_id = planos.id
ORDER BY valor_ajustado DESC;


CREATE VIEW vw_matriculas_ativas AS
SELECT
    alunos.nome AS aluno,
    alunos.cpf,
    modalidades.nome AS modalidade,
    modalidades.sala,
    itens_matricula.duracao_meses,
    matriculas.data_inicio
FROM matriculas
JOIN alunos
ON matriculas.aluno_id = alunos.id
JOIN itens_matricula
ON matriculas.id = itens_matricula.matricula_id
JOIN modalidades
ON itens_matricula.modalidade_id = modalidades.id
WHERE matriculas.status = 'Ativa';



CREATE VIEW vw_alunos_vip AS
SELECT
    alunos.nome AS aluno,
    SUM(
        (itens_matricula.valor_mensal_aplicado *
        itens_matricula.duracao_meses)
        + itens_matricula.taxa_adesao
    ) AS valor_total_investido
FROM alunos
JOIN matriculas
ON alunos.id = matriculas.aluno_id
JOIN itens_matricula
ON matriculas.id = itens_matricula.matricula_id
WHERE matriculas.status = 'Ativa'
GROUP BY alunos.nome;



SELECT
    modalidades.nome AS modalidade,
    modalidades.sala,
    modalidades.capacidade_maxima,
    planos.nome AS plano,
    planos.valor_mensal_base
FROM modalidades
JOIN planos
ON modalidades.plano_id = planos.id
WHERE modalidades.capacidade_maxima >= 15
AND planos.valor_mensal_base > 100.00
AND modalidades.disponivel = TRUE;


SELECT
    modalidades.nome AS modalidade,
    modalidades.sala,
    modalidades.capacidade_maxima,
    planos.nome AS plano,
    planos.valor_mensal_base
FROM modalidades
JOIN planos
ON modalidades.plano_id = planos.id
WHERE modalidades.capacidade_maxima >= 15
AND planos.valor_mensal_base > 100.00
AND modalidades.disponivel = TRUE;


CREATE VIEW vw_faturamento_medio_plano AS
SELECT
    planos.nome AS plano,
    SUM(
        (itens_matricula.valor_mensal_aplicado *
        itens_matricula.duracao_meses)
        + itens_matricula.taxa_adesao
    ) AS faturamento_total,
    AVG(itens_matricula.duracao_meses) AS media_duracao
FROM planos
JOIN modalidades
ON planos.id = modalidades.plano_id
JOIN itens_matricula
ON modalidades.id = itens_matricula.modalidade_id
JOIN matriculas
ON itens_matricula.matricula_id = matriculas.id
WHERE matriculas.status = 'Ativa'
GROUP BY planos.id, planos.nome;
