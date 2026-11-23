-- =====================================================================
-- PIX ANTIFRAUDE | CARGA PARA POSTGRESQL 14+
-- Compativel com 01_criacao_pix_antifraude.sql (19 tabelas)
-- Executar DEPOIS do DDL, no banco com schema pix_antifraude vazio.
-- Volume: 10 estados; 80 instituicoes; 12 servicos; 400 clientes;
--         1800 contas; 480 dispositivos; 30 tipos de golpe;
--         20000 transacoes PIX; 8000 alertas; 25 investigacoes;
--         500 investigados; ~1500 contestacoes.
-- Dados FICTICIOS e reproduziveis (nomes, CPFs e instituicoes
-- inventados); IDs explicitos.
-- Nao executar repetidamente sobre a mesma carga: IDs duplicados.
-- A carga nao exige extensoes e nao modifica o esquema/tabelas.
-- =====================================================================
BEGIN;
SET LOCAL search_path TO pix_antifraude, public;

-- 01. 10 estados ---------------------------------------------------
INSERT INTO estado (id_estado, sigla, nome, regiao_geografica) VALUES
 (1,'SP','São Paulo','SUDESTE'),        (2,'RJ','Rio de Janeiro','SUDESTE'),
 (3,'MG','Minas Gerais','SUDESTE'),     (4,'RS','Rio Grande do Sul','SUL'),
 (5,'PR','Paraná','SUL'),               (6,'BA','Bahia','NORDESTE'),
 (7,'PE','Pernambuco','NORDESTE'),      (8,'DF','Distrito Federal','CENTRO-OESTE'),
 (9,'AM','Amazonas','NORTE'),           (10,'SC','Santa Catarina','SUL');

-- 02. 12 servicos --------------------------------------------------
INSERT INTO servico (id_servico, nome) VALUES
 (1,'PIX'),(2,'TED'),(3,'Boleto'),(4,'Cartão de Crédito'),
 (5,'Cartão de Débito'),(6,'Empréstimo Pessoal'),(7,'Consignado'),
 (8,'Investimentos'),(9,'Câmbio'),(10,'Seguros'),
 (11,'Pix Parcelado'),(12,'Criptoativos');

-- 03. 80 instituicoes: 16 com nomes proprios ficticios, demais
--     numeradas. As 15 primeiras tem sede em SP (casos de
--     divisao relacional "servicos das instituicoes de SP").
INSERT INTO instituicao (id_instituicao, nome, tipo_instituicao, porte, data_autorizacao, id_estado)
SELECT s,
       CASE s
         WHEN 1 THEN 'Nexo Digital'            WHEN 2 THEN 'Cooperativa Serra Verde'
         WHEN 3 THEN 'PagFácil Pagamentos'     WHEN 4 THEN 'Banco Aurora'
         WHEN 5 THEN 'Vértice Bank'            WHEN 6 THEN 'Cooperativa Rio Doce'
         WHEN 7 THEN 'Ipê Pay'                 WHEN 8 THEN 'Banco Horizonte'
         WHEN 9 THEN 'Lume Fintech'            WHEN 10 THEN 'Cooperativa Mantiqueira'
         WHEN 11 THEN 'Carteira Já Pagamentos' WHEN 12 THEN 'Banco Atlântico'
         WHEN 13 THEN 'Órbita Digital'         WHEN 14 THEN 'Cooperativa Pampa'
         WHEN 15 THEN 'Prisma Pagamentos'      WHEN 16 THEN 'Banco Cerrado'
         ELSE (ARRAY['Banco ','Fintech ','Cooperativa ','Pagamentos '])[1 + (s % 4)]
              || LPAD(s::text,3,'0') END,
       (ARRAY['BANCO','FINTECH','COOPERATIVA','INSTITUICAO_PAGAMENTO'])[1 + (s % 4)],
       CASE WHEN s % 29 = 0 THEN 'SISTEMICO'
            WHEN s % 11 = 0 THEN 'GRANDE'
            WHEN s % 4 = 0  THEN 'MEDIO' ELSE 'PEQUENO' END,
       DATE '1995-01-01' + (s * 97 % 10000),
       CASE WHEN s <= 15 THEN 1 ELSE 2 + ((s - 16) % 9) END
FROM generate_series(1,80) AS s;

-- 04. Servicos por instituicao.
-- Todas oferecem PIX e mais um servico (2..11). As de SP (1..15) e
-- algumas outras oferecem um terceiro; algumas de SP oferecem TED.
-- Criptoativos (12) so existe fora de SP.
-- As instituicoes 1..5 juntas cobrem todos os servicos de SP.
INSERT INTO instituicao_servico (id_instituicao, id_servico)
SELECT s, 1 FROM generate_series(1,80) AS s;
INSERT INTO instituicao_servico (id_instituicao, id_servico)
SELECT s, 2 + (s % 10) FROM generate_series(1,80) AS s;
INSERT INTO instituicao_servico (id_instituicao, id_servico)
SELECT s, 2 + ((s + 5) % 10) FROM generate_series(1,80) AS s
WHERE s <= 15 OR s % 5 = 0;
INSERT INTO instituicao_servico (id_instituicao, id_servico)
SELECT s, 2 FROM generate_series(1,15) AS s
WHERE s % 3 = 0 AND s % 5 <> 0;      -- nunca duplica o TED ja gerado
INSERT INTO instituicao_servico (id_instituicao, id_servico)
SELECT s, 12 FROM generate_series(1,80) AS s
WHERE s > 40 AND s % 3 = 1;

-- 05. Incorporacoes (fusoes/aquisicoes), com cadeias de duas etapas:
-- Órbita -> Vértice -> Aurora; Lume -> Nexo -> Atlântico; etc.
INSERT INTO incorporacao (id_incorporada, id_incorporadora, data_incorporacao, tipo_operacao, valor_operacao) VALUES
 (13, 5,'2019-03-10','AQUISICAO', 450000000.00),
 ( 5, 4,'2022-08-01','FUSAO',     NULL),
 ( 9, 1,'2020-05-12','AQUISICAO', 120000000.00),
 ( 1,12,'2023-11-20','AQUISICAO',2300000000.00),
 (11, 3,'2018-02-14','AQUISICAO',  35000000.00),
 ( 3, 8,'2021-06-30','AQUISICAO', 610000000.00),
 (14, 2,'2017-09-01','FUSAO',     NULL),
 ( 2, 6,'2020-01-15','FUSAO',     NULL),
 (15, 7,'2019-10-05','AQUISICAO',  80000000.00),
 ( 7,16,'2024-04-22','AQUISICAO', 950000000.00),
 (20,16,'2016-07-19','AQUISICAO', 210000000.00),
 (25,12,'2018-12-03','AQUISICAO', 175000000.00),
 (70,25,'2015-05-27','FUSAO',     NULL),
 (33, 4,'2021-03-08','AQUISICAO',  99000000.00),
 (41, 8,'2022-11-11','AQUISICAO', 140000000.00),
 (47,16,'2023-02-28','FUSAO',     NULL),
 (52,12,'2024-09-09','AQUISICAO', 310000000.00),
 (60, 4,'2025-01-20','AQUISICAO', 520000000.00);

-- 06. 400 clientes. Os clientes 361..400 nao possuem conta (LEFT JOIN).
INSERT INTO cliente (id_cliente, nome, cpf, data_nascimento, cidade, data_cadastro, id_estado)
SELECT s,
       (ARRAY['Ana','Bruno','Carla','Diego','Elisa','Felipe','Gabriela','Hugo',
              'Isabela','João','Karina','Lucas','Mariana','Nicolas','Olivia','Pedro',
              'Quésia','Rafael','Sofia','Tiago','Úrsula','Vitor','Yasmin','Zeca'])[1 + (s % 24)]
       || ' ' ||
       (ARRAY['Silva','Souza','Oliveira','Santos','Lima','Pereira','Costa','Ferreira',
              'Almeida','Ribeiro','Carvalho','Gomes','Martins','Rocha','Barbosa','Araújo',
              'Mendes','Teixeira','Moura','Cardoso','Nunes','Freitas','Campos','Pinto'])[1 + ((s * 7) % 24)],
       LPAD((10000000000::bigint + s::bigint * 1000003)::text, 11, '0'),
       DATE '1960-01-01' + (s * 233 % 15000),
       CASE WHEN s % 19 = 0 THEN NULL
            ELSE (ARRAY['São Paulo','Rio de Janeiro','Belo Horizonte','Porto Alegre',
                        'Curitiba','Salvador','Recife','Brasília','Manaus',
                        'Florianópolis'])[1 + ((s - 1) % 10)] END,
       DATE '2022-01-01' + (s % 700),
       1 + ((s - 1) % 10)
FROM generate_series(1,400) AS s;

-- 07. 1800 contas para os clientes 1..360: em geral 5 por cliente, mas
-- clientes com id multiplo de 4 "cedem" duas contas ao cliente anterior
-- (ficam com 3; o anterior fica com 7).
-- Cliente 1 tem contas nas instituicoes 1..5 (todas de SP) -> cobre
-- todos os servicos oferecidos em SP (divisao relacional).
-- Contas 1501..1800 (clientes 301..360) nunca transacionam; parte delas
-- fica nas instituicoes 66..72, que nunca aparecem em transacoes.
-- Contas com id multiplo de 97 estao sem titular atual (ENCERRADA).
-- "Contas laranja": 1a conta dos clientes 30, 60, ..., 300 (score 95).
INSERT INTO conta (id_conta, apelido, agencia, numero, tipo_conta, saldo,
                   score_risco, status_conta, id_instituicao, id_cliente)
SELECT s,
       CASE WHEN s % 13 = 0 THEN NULL
            ELSE (ARRAY['Conta principal','Reserva de emergência','Salário',
                        'Pagamentos','Investimentos','Viagem'])[1 + (s % 6)] END,
       LPAD((1 + (s % 40))::text, 4, '0'),
       LPAD(s::text, 8, '0') || '-' || (s % 10),
       (ARRAY['CORRENTE','POUPANCA','PAGAMENTO','SALARIO'])[1 + (s % 4)],
       ((s::bigint * 7919) % 5000000) / 100.0,
       x.score,
       CASE WHEN s % 97 = 0 THEN 'ENCERRADA'
            WHEN x.score >= 90 THEN 'BLOQUEADA' ELSE 'ATIVA' END,
       CASE WHEN s <= 5 THEN s
            WHEN s > 1500 AND s % 3 = 0 THEN 66 + (s % 7)
            ELSE 1 + ((s * 37 - 1) % 65) END,
       CASE WHEN s % 97 = 0 THEN NULL
            WHEN s % 5 IN (0,4) AND (1 + (s - 1) / 5) % 4 = 0 THEN (s - 1) / 5
            ELSE 1 + ((s - 1) / 5) END
FROM generate_series(1,1800) AS s
CROSS JOIN LATERAL (
    SELECT CASE WHEN (s - 1) % 5 = 0 AND (1 + (s - 1) / 5) % 30 = 0 THEN 95
                WHEN s % 61 = 0 THEN 100
                ELSE (s * 13) % 91 END AS score
) x;

-- 08. 1800 aberturas. Contas 1..1200 abertas em 2025, demais em 2024.
-- Em 10% dos casos quem abriu a conta NAO e o titular atual
-- (transferencia de titularidade). Abertura em SP e frequente.
INSERT INTO abertura_conta (id_abertura, id_conta, id_cliente, data_abertura, id_estado, canal)
SELECT s, s,
       CASE WHEN s % 10 = 0 THEN 1 + ((((s - 1) / 5) + 11) % 360)
            ELSE COALESCE(c.id_cliente, 1 + ((s - 1) / 5)) END,
       CASE WHEN s <= 1200
            THEN TIMESTAMP '2025-01-01 08:00:00' + (s % 180) * INTERVAL '1 day'
                 + (s % 10) * INTERVAL '1 hour'
            ELSE TIMESTAMP '2024-01-01 08:00:00' + (s % 330) * INTERVAL '1 day'
                 + (s % 10) * INTERVAL '1 hour' END,
       CASE WHEN s % 4 = 0 THEN 1 ELSE 1 + ((s * 3) % 10) END,
       (ARRAY['APP','INTERNET_BANKING','AGENCIA','CORRESPONDENTE','OUTRO'])[1 + (s % 5)]
FROM generate_series(1,1800) AS s
JOIN conta c ON c.id_conta = s;

-- 09. 30 tipos de golpe (14 nomeados + 16 catalogados).
INSERT INTO tipo_golpe (id_tipo_golpe, nome, severidade, taxa_recuperacao, categoria, id_servico)
SELECT s,
       CASE s
         WHEN 1 THEN 'Falsa Central de Atendimento' WHEN 2 THEN 'Golpe do Falso Parente'
         WHEN 3 THEN 'Phishing por SMS'             WHEN 4 THEN 'Boleto Adulterado'
         WHEN 5 THEN 'Clonagem de WhatsApp'         WHEN 6 THEN 'Falso Funcionário do Banco'
         WHEN 7 THEN 'Pix Agendado Falso'           WHEN 8 THEN 'Mão Fantasma (acesso remoto)'
         WHEN 9 THEN 'Conta Laranja'                WHEN 10 THEN 'Documento Falsificado'
         WHEN 11 THEN 'QR Code Adulterado'          WHEN 12 THEN 'Falsa Loja Virtual'
         WHEN 13 THEN 'Falso Investimento'          WHEN 14 THEN 'Sequestro de Chip (SIM swap)'
         ELSE 'Golpe catalogado ' || LPAD(s::text,3,'0') END,
       CASE WHEN s = 1 THEN 95                 -- maior severidade isolada
            WHEN s % 7 = 0 THEN 15 ELSE 20 + ((s * 9) % 81) END,
       (5 + (s * 7) % 60)::numeric(5,2),
       CASE WHEN s <= 14 THEN
              (ARRAY['ENGENHARIA_SOCIAL','ENGENHARIA_SOCIAL','TECNICO','DOCUMENTAL',
                     'TECNICO','ENGENHARIA_SOCIAL','ENGENHARIA_SOCIAL','TECNICO',
                     'DOCUMENTAL','DOCUMENTAL','TECNICO','ENGENHARIA_SOCIAL',
                     'ENGENHARIA_SOCIAL','TECNICO'])[s]
            ELSE (ARRAY['DOCUMENTAL','ENGENHARIA_SOCIAL','TECNICO'])[1 + (s % 3)] END,
       CASE WHEN s <= 14 THEN (ARRAY[1,1,1,3,1,1,1,1,1,1,1,4,8,1])[s]
            ELSE 1 + ((s - 1) % 12) END
FROM generate_series(1,30) AS s;

-- 10. Tres golpes de exposicao por instituicao (240 vinculos).
INSERT INTO instituicao_golpe (id_instituicao, id_tipo_golpe, nivel_exposicao)
SELECT i, 1 + (((i - 1) * 7 + k * 11) % 30), 1 + k * 30
FROM generate_series(1,80) AS i
CROSS JOIN generate_series(0,2) AS k;

-- 11. Contas identificadas em golpes.
-- Contas comuns (id multiplo de 6, ate 1500): dois golpes cada.
INSERT INTO conta_golpe (id_conta, id_tipo_golpe, data_identificacao)
SELECT s, 1 + (((s * 7) + k * 13) % 30), DATE '2025-08-01' + (s % 400) + k * 5
FROM generate_series(6,1500,6) AS s
CROSS JOIN generate_series(0,1) AS k;
-- Contas laranja 146, 296, 446: TODOS os golpes de engenharia social.
-- Demais contas laranja: apenas os de id par (divisao relacional).
INSERT INTO conta_golpe (id_conta, id_tipo_golpe, data_identificacao)
SELECT m.id_conta, g.id_tipo_golpe, DATE '2025-09-01' + (g.id_tipo_golpe * 3)
FROM (SELECT (c - 1) * 5 + 1 AS id_conta, c FROM generate_series(30,300,30) AS c) m
JOIN tipo_golpe g ON g.categoria = 'ENGENHARIA_SOCIAL'
WHERE m.c <= 90 OR g.id_tipo_golpe % 2 = 0;

-- 12. 480 dispositivos: 1 principal por cliente 1..360 (id = id_cliente)
--     e 1 secundario para os clientes 1..120 (id = 360 + id_cliente).
INSERT INTO dispositivo (id_dispositivo, id_cliente, modelo, sistema, data_cadastro, confiavel)
SELECT c, c,
       (ARRAY['Galaxy A54','iPhone 13','Moto G84','Redmi Note 12','iPhone 15',
              'Navegador Chrome','Galaxy S23','Navegador Safari'])[1 + (c % 8)],
       (ARRAY['ANDROID','IOS','ANDROID','ANDROID','IOS','WEB','ANDROID','WEB'])[1 + (c % 8)],
       DATE '2024-01-01' + (c % 300),
       c % 9 <> 0
FROM generate_series(1,360) AS c;
INSERT INTO dispositivo (id_dispositivo, id_cliente, modelo, sistema, data_cadastro, confiavel)
SELECT 360 + c, c,
       (ARRAY['iPad Air','Galaxy Tab S9','Navegador Firefox'])[1 + (c % 3)],
       (ARRAY['IOS','ANDROID','WEB'])[1 + (c % 3)],
       DATE '2024-06-01' + (c % 200),
       c % 4 <> 0
FROM generate_series(1,120) AS c;

-- 13. Vinculos dispositivo-conta.
-- Historico encerrado: o dispositivo de quem ABRIU a conta, quando
-- difere do titular atual, ou quando a conta ficou sem titular.
INSERT INTO dispositivo_conta (id_vinculo, id_dispositivo, id_conta, data_vinculo, data_desvinculo)
SELECT 2000 + c.id_conta, a.id_cliente, c.id_conta,
       a.data_abertura::date,
       CASE WHEN c.id_cliente IS NULL THEN DATE '2025-12-31'
            ELSE a.data_abertura::date + 30 END
FROM conta c
JOIN abertura_conta a ON a.id_conta = c.id_conta
WHERE c.id_cliente IS NULL OR c.id_cliente <> a.id_cliente;
-- Vinculo ATIVO com o dispositivo principal do titular atual.
INSERT INTO dispositivo_conta (id_vinculo, id_dispositivo, id_conta, data_vinculo, data_desvinculo)
SELECT c.id_conta, c.id_cliente, c.id_conta,
       CASE WHEN c.id_cliente <> a.id_cliente THEN a.data_abertura::date + 30
            ELSE a.data_abertura::date END,
       NULL
FROM conta c
JOIN abertura_conta a ON a.id_conta = c.id_conta
WHERE c.id_cliente IS NOT NULL;

-- 14. Chaves PIX.
-- ALEATORIA: uma por conta (encerrada se a conta nao tem titular).
INSERT INTO chave_pix (id_chave, id_conta, tipo_chave, valor_chave, data_registro, data_exclusao)
SELECT c.id_conta, c.id_conta, 'ALEATORIA',
       substr(m, 1, 8) || '-' || substr(m, 9, 4) || '-' || substr(m, 13, 4) || '-'
       || substr(m, 17, 4) || '-' || substr(m, 21, 12),
       a.data_abertura::date + 1,
       CASE WHEN c.id_cliente IS NULL THEN DATE '2025-12-31' END
FROM conta c
JOIN abertura_conta a ON a.id_conta = c.id_conta
CROSS JOIN LATERAL (SELECT md5('chave-' || c.id_conta) AS m) h;
-- CPF: na primeira conta de cada cliente (id_conta % 5 = 1).
INSERT INTO chave_pix (id_chave, id_conta, tipo_chave, valor_chave, data_registro, data_exclusao)
SELECT 2000 + c.id_conta, c.id_conta, 'CPF', cl.cpf, a.data_abertura::date + 2, NULL
FROM conta c
JOIN cliente cl ON cl.id_cliente = c.id_cliente
JOIN abertura_conta a ON a.id_conta = c.id_conta
WHERE c.id_conta % 5 = 1;
-- EMAIL: contas pares com titular.
INSERT INTO chave_pix (id_chave, id_conta, tipo_chave, valor_chave, data_registro, data_exclusao)
SELECT 4000 + c.id_conta, c.id_conta, 'EMAIL',
       'cliente' || c.id_cliente || '.conta' || c.id_conta || '@email.com',
       a.data_abertura::date + 3, NULL
FROM conta c
JOIN abertura_conta a ON a.id_conta = c.id_conta
WHERE c.id_conta % 2 = 0 AND c.id_cliente IS NOT NULL;
-- TELEFONE: segunda conta de cada cliente (id_conta % 5 = 2).
INSERT INTO chave_pix (id_chave, id_conta, tipo_chave, valor_chave, data_registro, data_exclusao)
SELECT 6000 + c.id_conta, c.id_conta, 'TELEFONE',
       '+55' || (ARRAY['11','21','31','51','41','71','81','61','92','48'])[cl.id_estado]
       || '9' || LPAD(((cl.id_cliente::bigint * 7919) % 100000000)::text, 8, '0'),
       a.data_abertura::date + 4, NULL
FROM conta c
JOIN cliente cl ON cl.id_cliente = c.id_cliente
JOIN abertura_conta a ON a.id_conta = c.id_conta
WHERE c.id_conta % 5 = 2;
-- Historico: chaves aleatorias antigas, ja excluidas.
INSERT INTO chave_pix (id_chave, id_conta, tipo_chave, valor_chave, data_registro, data_exclusao)
SELECT 8000 + c.id_conta, c.id_conta, 'ALEATORIA',
       substr(m, 1, 8) || '-' || substr(m, 9, 4) || '-' || substr(m, 13, 4) || '-'
       || substr(m, 17, 4) || '-' || substr(m, 21, 12),
       a.data_abertura::date + 1, a.data_abertura::date + 90
FROM conta c
JOIN abertura_conta a ON a.id_conta = c.id_conta
CROSS JOIN LATERAL (SELECT md5('antiga-' || c.id_conta) AS m) h
WHERE c.id_conta % 7 = 0;

-- 15. 20000 transacoes PIX entre contas 1..1500 com titular.
-- Tabelas temporarias apenas para facilitar a geracao.
CREATE TEMP TABLE tmp_contas ON COMMIT DROP AS
SELECT ROW_NUMBER() OVER (ORDER BY id_conta) AS idx, id_conta, id_cliente
FROM conta
WHERE id_conta <= 1500 AND id_cliente IS NOT NULL;

-- Regras de geracao:
--  * t % 26 = 0 -> origem e a 1a conta dos clientes 1..20 (vitimas
--    frequentes; todas essas transacoes serao contestadas);
--  * t % 10 = 0 -> destino e uma das 10 contas laranja;
--  * t % 40 = 0 CANCELADA, t % 40 = 39 AGENDADA (futuro), demais CONCLUIDA.
CREATE TEMP TABLE tmp_tx ON COMMIT DROP AS
SELECT t,
       CASE WHEN t % 26 = 0 THEN ((t / 26) % 20) * 5 + 1
            ELSE (SELECT id_conta FROM tmp_contas
                  WHERE idx = 1 + ((t * 37) % (SELECT COUNT(*) FROM tmp_contas))) END AS origem,
       CASE WHEN t % 10 = 0 THEN (((t / 10) % 10) + 1) * 150 - 4
            ELSE (SELECT id_conta FROM tmp_contas
                  WHERE idx = 1 + ((t * 53 + 7) % (SELECT COUNT(*) FROM tmp_contas))) END AS destino
FROM generate_series(1,20000) AS t;

-- Se origem = destino, o destino passa a ser a conta seguinte valida.
UPDATE tmp_tx x
SET destino = (SELECT MIN(id_conta) FROM tmp_contas WHERE id_conta > x.origem)
WHERE x.origem = x.destino;

INSERT INTO transacao_pix (id_transacao, id_conta_origem, id_conta_destino, id_dispositivo,
                           valor, data_hora, status, descricao)
SELECT x.t, x.origem, x.destino,
       CASE WHEN x.t % 15 = 0 THEN NULL
            WHEN c.id_cliente <= 120 AND x.t % 4 = 0 THEN 360 + c.id_cliente
            ELSE c.id_cliente END,
       CASE WHEN x.t % 10 = 0 THEN 800 + ((x.t::bigint * 7919) % 1500000) / 100.0
            ELSE 5 + ((x.t::bigint * 7919) % 250000) / 100.0 END,
       CASE WHEN x.t % 40 = 39
            THEN TIMESTAMP '2026-12-01 09:00:00' + (x.t % 60) * INTERVAL '1 day'
            ELSE TIMESTAMP '2025-07-01 00:00:00' + (x.t % 480) * INTERVAL '1 day'
                 + ((x.t * 7) % 24) * INTERVAL '1 hour'
                 + ((x.t * 13) % 60) * INTERVAL '1 minute' END,
       CASE WHEN x.t % 40 = 0 THEN 'CANCELADA'
            WHEN x.t % 40 = 39 THEN 'AGENDADA' ELSE 'CONCLUIDA' END,
       CASE x.t % 6 WHEN 0 THEN NULL WHEN 1 THEN 'Aluguel' WHEN 2 THEN 'Mercado'
                    WHEN 3 THEN 'Divisão da conta' WHEN 4 THEN 'Presente'
                    ELSE 'Pagamento de serviço' END
FROM tmp_tx x
JOIN conta c ON c.id_conta = x.origem;

-- 16. 8000 alertas do motor antifraude (t % 5 IN (0,1)).
-- Transacoes para contas laranja geram alertas de score alto,
-- nunca falso positivo. falso_positivo NULL = nao analisado.
INSERT INTO alerta (id_alerta, id_transacao, id_tipo_golpe, score, data_hora, falso_positivo)
SELECT ROW_NUMBER() OVER (ORDER BY tp.id_transacao), tp.id_transacao,
       1 + ((tp.id_transacao * 7) % 30),
       CASE WHEN tp.id_transacao % 10 = 0 THEN 80 + (tp.id_transacao % 21)
            ELSE 20 + ((tp.id_transacao * 13) % 61) END,
       tp.data_hora + (tp.id_transacao % 50) * INTERVAL '1 second',
       CASE WHEN tp.id_transacao % 10 = 0 THEN FALSE
            WHEN tp.id_transacao % 15 = 1 THEN NULL
            WHEN tp.id_transacao % 5 = 1 THEN TRUE ELSE FALSE END
FROM transacao_pix tp
WHERE tp.id_transacao % 5 IN (0,1);

-- 17. 25 investigacoes, de ago/2025 a out/2026.
INSERT INTO investigacao (id_investigacao, nome, orgao, data_inicio, data_fim, valor_bloqueado, id_estado)
SELECT s,
       CASE WHEN s <= 12 THEN 'Operação ' ||
              (ARRAY['Teia','Laranja Mecânica','Chave Mestra','Espelho','Dupla Face',
                     'Clone','Rastro','Anzol','Falsa Central','Código Zero',
                     'Mão Fantasma','Ponte'])[s]
            ELSE 'Investigação Interna ' || LPAD(s::text,3,'0') END,
       CASE WHEN s > 12 THEN 'COMPLIANCE'
            ELSE (ARRAY['POLICIA_CIVIL','POLICIA_FEDERAL','BACEN'])[1 + (s % 3)] END,
       DATE '2025-08-01' + (s - 1) * 18,
       DATE '2025-08-01' + (s - 1) * 18 + 45,
       (50000 + s * 12345.67)::numeric(16,2),
       1 + ((s - 1) % 10)
FROM generate_series(1,25) AS s;

-- 18. 500 investigados: 20 por investigacao, clientes distintos.
-- O cliente 30 (dono de conta laranja) esta em TODAS; os demais
-- vem de 31..280. Clientes 1..29 e 281..400 nunca sao investigados.
INSERT INTO investigado (id_investigado, id_investigacao, id_cliente, id_dispositivo, data_inclusao)
SELECT (inv - 1) * 20 + pos, inv, x.cli, x.cli,
       DATE '2025-08-01' + (inv - 1) * 18 + pos
FROM generate_series(1,25) AS inv
CROSS JOIN generate_series(1,20) AS pos
CROSS JOIN LATERAL (
    SELECT CASE WHEN pos = 1 THEN 30
                ELSE 31 + ((inv * 11 + pos - 2) % 250) END AS cli
) x;

-- 19. Contestacoes: transacoes CONCLUIDAS com id multiplo de 13.
-- c = numero sequencial da contestacao.
--   c % 15 = 0  -> CANCELADA;  c % 15 = 14 -> EM_ANALISE;
--   demais CONCLUIDA: c % 9 = 0 PARCIAL, c % 4 = 0 NEGADO, senao DEVOLVIDO.
-- Algumas pertencem a investigacoes (c % 3 = 0 ou c % 7 = 0).
INSERT INTO contestacao (id_contestacao, id_transacao, id_tipo_golpe, id_investigacao,
                         data_abertura, situacao, resultado, valor_devolvido)
SELECT y.c, y.id_transacao,
       1 + (y.id_transacao % 30),
       CASE WHEN y.c % 3 = 0 THEN 1 + ((y.c / 3) % 25)
            WHEN y.c % 7 = 0 THEN 1 + ((y.c / 7) % 5) END,
       y.data_hora + (1 + y.id_transacao % 5) * INTERVAL '1 day',
       y.situacao, y.resultado,
       CASE y.resultado WHEN 'DEVOLVIDO' THEN y.valor
                        WHEN 'PARCIAL' THEN ROUND(y.valor * 0.5, 2)
                        ELSE 0 END
FROM (
    SELECT z.*,
           CASE WHEN z.c % 15 = 0 THEN 'CANCELADA'
                WHEN z.c % 15 = 14 THEN 'EM_ANALISE' ELSE 'CONCLUIDA' END AS situacao,
           CASE WHEN z.c % 15 IN (0,14) THEN NULL
                WHEN z.c % 9 = 0 THEN 'PARCIAL'
                WHEN z.c % 4 = 0 THEN 'NEGADO' ELSE 'DEVOLVIDO' END AS resultado
    FROM (
        SELECT ROW_NUMBER() OVER (ORDER BY tp.id_transacao) AS c,
               tp.id_transacao, tp.valor, tp.data_hora
        FROM transacao_pix tp
        WHERE tp.status = 'CONCLUIDA' AND tp.id_transacao % 13 = 0
    ) z
) y;

-- 20. Ajustar sequences/identities para INSERTs posteriores.
SELECT setval(pg_get_serial_sequence('pix_antifraude.estado','id_estado'), 10, true);
SELECT setval(pg_get_serial_sequence('pix_antifraude.servico','id_servico'), 12, true);
SELECT setval(pg_get_serial_sequence('pix_antifraude.instituicao','id_instituicao'), 80, true);
SELECT setval(pg_get_serial_sequence('pix_antifraude.cliente','id_cliente'), 400, true);
SELECT setval(pg_get_serial_sequence('pix_antifraude.conta','id_conta'), 1800, true);
SELECT setval(pg_get_serial_sequence('pix_antifraude.abertura_conta','id_abertura'), 1800, true);
SELECT setval(pg_get_serial_sequence('pix_antifraude.tipo_golpe','id_tipo_golpe'), 30, true);
SELECT setval(pg_get_serial_sequence('pix_antifraude.dispositivo','id_dispositivo'), 480, true);
SELECT setval(pg_get_serial_sequence('pix_antifraude.dispositivo_conta','id_vinculo'),
              (SELECT MAX(id_vinculo) FROM pix_antifraude.dispositivo_conta), true);
SELECT setval(pg_get_serial_sequence('pix_antifraude.chave_pix','id_chave'),
              (SELECT MAX(id_chave) FROM pix_antifraude.chave_pix), true);
SELECT setval(pg_get_serial_sequence('pix_antifraude.transacao_pix','id_transacao'), 20000, true);
SELECT setval(pg_get_serial_sequence('pix_antifraude.alerta','id_alerta'), 8000, true);
SELECT setval(pg_get_serial_sequence('pix_antifraude.investigacao','id_investigacao'), 25, true);
SELECT setval(pg_get_serial_sequence('pix_antifraude.investigado','id_investigado'), 500, true);
SELECT setval(pg_get_serial_sequence('pix_antifraude.contestacao','id_contestacao'),
              (SELECT MAX(id_contestacao) FROM pix_antifraude.contestacao), true);

-- 21. Validacao automatica. Se algum total estiver incorreto,
--     a transacao falha e a carga inteira e revertida.
DO $$
DECLARE
    rec RECORD;
    total_obtido BIGINT;
BEGIN
    FOR rec IN
        SELECT * FROM (VALUES
            ('estado',10),('servico',12),('instituicao',80),
            ('instituicao_servico',205),('incorporacao',18),
            ('cliente',400),('conta',1800),('abertura_conta',1800),
            ('tipo_golpe',30),('instituicao_golpe',240),('conta_golpe',575),
            ('dispositivo',480),('dispositivo_conta',1979),('chave_pix',3660),
            ('transacao_pix',20000),('alerta',8000),
            ('investigacao',25),('investigado',500),('contestacao',1461)
        ) AS esperado(tabela, quantidade)
    LOOP
        EXECUTE format('SELECT COUNT(*) FROM pix_antifraude.%I', rec.tabela)
           INTO total_obtido;
        IF total_obtido <> rec.quantidade THEN
            RAISE EXCEPTION 'Tabela %: esperado %, encontrado %',
                rec.tabela, rec.quantidade, total_obtido;
        END IF;
        RAISE NOTICE '%: % registros OK', rec.tabela, total_obtido;
    END LOOP;

    IF (SELECT COUNT(*) FROM pix_antifraude.transacao_pix WHERE status = 'CONCLUIDA') <> 19000 THEN
        RAISE EXCEPTION 'Quantidade incorreta de transacoes concluidas';
    END IF;

    -- Toda contestacao concluida tem valor devolvido coerente com o resultado.
    IF EXISTS (
        SELECT 1 FROM pix_antifraude.contestacao ct
        JOIN pix_antifraude.transacao_pix tp ON tp.id_transacao = ct.id_transacao
        WHERE ct.situacao = 'CONCLUIDA' AND NOT (
              (ct.resultado = 'DEVOLVIDO' AND ct.valor_devolvido = tp.valor) OR
              (ct.resultado = 'PARCIAL' AND ct.valor_devolvido > 0 AND ct.valor_devolvido < tp.valor) OR
              (ct.resultado = 'NEGADO' AND ct.valor_devolvido = 0))
    ) THEN RAISE EXCEPTION 'Contestacoes com devolucao inconsistente'; END IF;

    -- Nenhuma chave ativa duplicada e no maximo 5 ativas por conta.
    IF EXISTS (
        SELECT 1 FROM pix_antifraude.chave_pix
        WHERE data_exclusao IS NULL
        GROUP BY id_conta HAVING COUNT(*) > 5
    ) THEN RAISE EXCEPTION 'Conta com mais de 5 chaves ativas'; END IF;

    -- O caso de divisao relacional precisa existir: o cliente 1 cobre
    -- todos os servicos oferecidos por instituicoes sediadas em SP.
    IF EXISTS (
        SELECT 1 FROM pix_antifraude.instituicao_servico isv
        JOIN pix_antifraude.instituicao i ON i.id_instituicao = isv.id_instituicao
        JOIN pix_antifraude.estado e ON e.id_estado = i.id_estado
        WHERE e.sigla = 'SP'
          AND isv.id_servico NOT IN (
              SELECT isv2.id_servico
              FROM pix_antifraude.conta c
              JOIN pix_antifraude.instituicao_servico isv2 ON isv2.id_instituicao = c.id_instituicao
              WHERE c.id_cliente = 1)
    ) THEN RAISE EXCEPTION 'Caso de divisao relacional ausente'; END IF;

    RAISE NOTICE 'CARGA PIX ANTIFRAUDE CONCLUIDA COM SUCESSO';
END $$;
COMMIT;

-- Consultas de verificacao opcionais apos a carga:
-- SELECT status, COUNT(*) FROM pix_antifraude.transacao_pix GROUP BY status;
-- SELECT situacao, resultado, COUNT(*) FROM pix_antifraude.contestacao GROUP BY situacao, resultado;
-- SELECT COUNT(*) FROM pix_antifraude.cliente cl WHERE NOT EXISTS
--   (SELECT 1 FROM pix_antifraude.conta c WHERE c.id_cliente = cl.id_cliente);
