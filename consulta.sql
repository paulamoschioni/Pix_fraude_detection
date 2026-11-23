-- CONSULTA 01:     
SELECT	c.id_conta AS identificadorConta,
		c.apelido AS apelido,
		i.nome AS nomeInstituicao,
		cl.nome AS titular,
		c.score_risco AS score

FROM conta c
JOIN instituicao i ON i.id_instituicao = c.id_instituicao
JOIN cliente cl ON cl.id_cliente = c.id_cliente
WHERE c.score_risco > 80 
ORDER BY c.score_risco, cl.nome DESC;


-- CONSULTA 02:
SET search_path TO pix_antifraude;

SELECT DISTINCT e.sigla AS estado,
                s.nome  AS servicos

FROM cliente c
JOIN estado e ON e.id_estado = c.id_estado                    -- estado onde o cliente MORA
JOIN conta co ON co.id_cliente = c.id_cliente                 -- contas que o cliente TEM (era o que faltava)
JOIN instituicao_servico ins ON ins.id_instituicao = co.id_instituicao  -- serviços do banco de cada conta
JOIN servico s ON s.id_servico = ins.id_servico               -- traduz id_servico -> nome
ORDER BY e.sigla, s.nome;


-- CONSULTA 03:
SELECT  c.nome AS cliente,
        COUNT(ct.id_conta) AS qtde_contas,                                  
        COUNT(ct.id_conta) FILTER (WHERE ct.score_risco >= 70) AS contas_risco_alto  

FROM cliente c                                    
LEFT JOIN conta ct ON ct.id_cliente = c.id_cliente 
GROUP BY c.id_cliente, c.nome                      
ORDER BY qtde_contas DESC;  


-- CONSULTA 04: