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
SET search_path TO pix_antifraude;

SELECT  c.nome AS cliente,          -- quem ABRIU a conta
        co.apelido,
        i.nome AS instituicao,
        a.canal,
        e.sigla,
        a.data_abertura

FROM abertura_conta a                                       
INNER JOIN cliente c ON c.id_cliente = a.id_cliente         
JOIN conta co ON co.id_conta = a.id_conta                   
JOIN instituicao i ON i.id_instituicao = co.id_instituicao  
JOIN estado e ON e.id_estado = a.id_estado                  
WHERE a.data_abertura >= '2025-01-01'
  AND a.data_abertura <  '2026-01-01';                      



  -- CONSULTA 05:
SET search_path TO pix_antifraude;

SELECT  c.nome AS cliente,
        COUNT(co.id_conta)                AS total_contas,      
        COUNT(DISTINCT co.id_instituicao) AS num_instituicoes,  
        ROUND(AVG(co.score_risco), 2)     AS score_medio        
FROM cliente c
JOIN conta co ON co.id_cliente = c.id_cliente
GROUP BY c.id_cliente, c.nome                     
   AND AVG(co.score_risco) > 50;                



-- CONSULTA 06:
SET search_path TO pix_antifraude;

SELECT  i.nome AS investigacao,
        COUNT(co.id_investigacao) AS contestacoes_concluidas,                  
        COUNT(co.id_investigacao) FILTER (WHERE co.resultado = 'PARCIAL') AS parciais,  
        ROUND(100.0 * COUNT(co.id_investigacao) FILTER (WHERE co.resultado = 'PARCIAL')
                    / COUNT(co.id_investigacao), 2) AS pct_parciais           

FROM investigacao i
JOIN contestacao co ON co.id_investigacao = i.id_investigacao
WHERE co.situacao = 'CONCLUIDA'            
GROUP BY i.id_investigacao, i.nome         
HAVING COUNT(co.id_investigacao) >= 20;      



-- CONSULTA 07:
SELECT	c.apelido AS conta,
		c.score_risco AS score,
		(SELECT ROUND(AVG(c2.score_risco), 2)
		 FROM conta c2
		 WHERE c2.id_instituicao = c.id_instituicao) AS media_instituicao

FROM conta c
WHERE c.score_risco > (SELECT AVG(c2.score_risco)
					   FROM conta c2
					   WHERE c2.id_instituicao = c.id_instituicao
						) -- aq calcula a media dos scores d contas d msm instit.
						  -- com + de 20 contas apenas DESSA instit.
AND (SELECT COUNT(*)
	 FROM conta c2
	 WHERE c2.id_instituicao = c.id_instituicao) >= 20;
	



-- CONSULTA 08: 
SELECT	c.nome AS cliente,
		c.id_cliente AS identificador

FROM cliente c
WHERE	NOT EXISTS(SELECT *
				   FROM investigado i2
				   WHERE i2.id_cliente = c.id_cliente
				 )
  AND   EXISTS(SELECT *
  			   FROM conta co
			   WHERE co.id_cliente = c.id_cliente)



-- CONSULTA 09: 
SELECT DISTINCT	t.nome, 
		t.categoria,
		t.severidade

FROM tipo_golpe t
WHERE t.severidade > (SELECT MAX(t2.severidade)
					  FROM tipo_golpe t2
					  WHERE t2.categoria = t.categoria
					  AND t2.id_tipo_golpe <> t.id_tipo_golpe
					  );



-- CONSULTA 10: 
SELECT	inst.nome AS incorporada,
		inst2.nome AS incorporadora,
		i.tipo_operacao,
		i.valor_operacao AS valor,
		i.data_incorporacao
		
FROM incorporacao i
JOIN instituicao inst ON inst.id_instituicao = i.id_incorporada
JOIN instituicao inst2 ON inst2.id_instituicao = i.id_incorporadora
ORDER BY incorporada;



-- CONSULTA 11:
--contestacao -> transacao_pix -> conta (ORIGEM) -> cliente (vítima)

SELECT  c.nome AS cliente,
        c.id_cliente,
        COUNT(*) FILTER (WHERE co.resultado = 'DEVOLVIDO') AS devolvidas,   
        COUNT(*) AS total,                                                  
        ROUND(100.0 * COUNT(*) FILTER (WHERE co.resultado = 'DEVOLVIDO')
                    / COUNT(*), 2) AS percentual

FROM contestacao co
JOIN transacao_pix tp ON tp.id_transacao = co.id_transacao    
JOIN conta ct         ON ct.id_conta = tp.id_conta_origem     
JOIN cliente c        ON c.id_cliente = ct.id_cliente         
WHERE co.situacao = 'CONCLUIDA'                               
GROUP BY c.id_cliente, c.nome                                 
HAVING COUNT(*) >= 10                                         
   AND 100.0 * COUNT(*) FILTER (WHERE co.resultado = 'DEVOLVIDO')
             / COUNT(*) > 70;                                 



-- CONSULTA 12: 
SET search_path TO pix_antifraude;

SELECT i.nome AS instituicao
FROM instituicao i
WHERE EXISTS (SELECT *                                 
              FROM conta c
              WHERE c.id_instituicao = i.id_instituicao)        
  AND NOT EXISTS (SELECT *                            
                  FROM transacao_pix t
                  JOIN conta c2 ON c2.id_conta = t.id_conta_origem     
                  WHERE c2.id_instituicao = i.id_instituicao)          
  AND NOT EXISTS (SELECT *                            
                  FROM transacao_pix t2
                  JOIN conta c3 ON c3.id_conta = t2.id_conta_destino    
                  WHERE c3.id_instituicao = i.id_instituicao);



-- CONSULTA 13:
SET search_path TO pix_antifraude;

SELECT  t.id_transacao AS identificador,
        t.valor,
        t.data_hora AS data,
        ROUND((SELECT AVG(t3.valor)                    
               FROM transacao_pix t3
               WHERE t3.status = 'CONCLUIDA'), 2) AS media

FROM transacao_pix t
WHERE t.status = 'CONCLUIDA'
  AND t.data_hora >= '2026-10-01'                      
  AND t.data_hora <  '2026-11-01'
  AND t.valor > (SELECT AVG(t2.valor)
                 FROM transacao_pix t2
                 WHERE t2.status = 'CONCLUIDA')        
ORDER BY t.valor DESC;


-- CONSULTA 14
SET search_path TO pix_antifraude;

SELECT DISTINCT c.id_cliente AS identificador,
                c.nome

FROM cliente c
WHERE c.id_cliente IN (SELECT a.id_cliente              -- lista de quem abriu conta em MG
                       FROM abertura_conta a
                       JOIN estado e ON e.id_estado = a.id_estado
                       WHERE e.sigla = 'MG')
ORDER BY c.id_cliente;



-- CONSULTA 15A
