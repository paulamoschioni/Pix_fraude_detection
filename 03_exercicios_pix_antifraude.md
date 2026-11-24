# PIX Antifraude: lista de exercícios de SQL

**Orientações**

- Resolva cada problema usando **apenas SELECT**, sem modificar os registros.
- Antes de começar, rode `SET search_path TO pix_antifraude;`.
- Considere o schema `pix_antifraude` e as regras de integridade do DDL (`01_criacao_pix_antifraude.sql`).
- Não use `COALESCE` nem CTEs (`WITH ... AS`).
- Quando o enunciado pedir **subconsulta independente**, não relacione as colunas dela a apelidos da consulta externa.
- Cada questão mostra quantas linhas o resultado deve ter. Use isso para se conferir antes de abrir o gabarito (`04_gabarito_pix_antifraude.sql`).

**Lembretes do domínio**

- O **titular atual** de uma conta está em `conta.id_cliente`, que pode ser nulo. **Quem abriu** a conta está em `abertura_conta.id_cliente`.
- A **vítima** de uma contestação é o titular da conta de **origem** da transação.
- Contestação **concluída** tem resultado `DEVOLVIDO`, `PARCIAL` ou `NEGADO`. As que estão `EM_ANALISE` ou `CANCELADA` têm resultado nulo.

---

## 01. Seleção, filtros e ordenação

Liste as contas com **score de risco 80 ou superior** que possuem titular atual. Exiba o identificador da conta, o apelido (que pode ser nulo), o nome da instituição, o nome do titular e o score. Ordene pelo score decrescente e, em caso de empate, pelo nome do titular.

> Resultado esperado: **41 linhas**



## 02. DISTINCT, N:N, múltiplas junções

Relacione, sem repetições, os pares **(sigla do estado onde o cliente mora, serviço oferecido pelas instituições onde ele tem conta atualmente)**. Ordene por estado e serviço.

> Resultado esperado: **120 linhas**



## 03. LEFT JOIN e contagens condicionais

Liste **TODOS** os clientes, inclusive os que não possuem conta. Exiba o nome, a quantidade de contas atuais e quantas delas têm score de risco de pelo menos 70. Ordene pela quantidade total, decrescente.

> Resultado esperado: **400 linhas**



## 04. INNER JOIN e intervalo de datas

Exiba todas as **aberturas de conta realizadas em 2025**: o cliente que **abriu** a conta, o apelido da conta, a instituição, o canal, a sigla do estado onde a conta foi aberta e a data. Considere o histórico de abertura, não o titular atual.

> Resultado esperado: **1200 linhas**



## 05. GROUP BY, HAVING, COUNT DISTINCT

Identifique os clientes que possuem atualmente contas em **pelo menos 3 instituições distintas** e cujo **score médio** seja maior que 50. Mostre o total de contas, o número de instituições e o score médio, com duas casas decimais.

> Resultado esperado: **98 linhas**



## 06. HAVING, contagem condicional e porcentagem

Para cada investigação com **pelo menos 20 contestações CONCLUÍDAS**, apresente o total de contestações concluídas, quantas tiveram resultado **PARCIAL** e a porcentagem de parciais, com duas casas decimais.

> Resultado esperado: **11 linhas**



## 07. Subconsulta correlacionada

Mostre as contas cujo score de risco **supera a média de score das contas da MESMA instituição**, considerando apenas instituições com pelo menos 20 contas. Exiba o score da conta e a média da instituição.

> Resultado esperado: **822 linhas**



## 08. EXISTS e NOT EXISTS

Encontre os clientes que possuem **pelo menos uma conta**, mas que **nunca foram investigados**. Mostre o identificador e o nome.

> Resultado esperado: **109 linhas**



## 09. Subconsulta com ALL

Liste os tipos de golpe com **severidade estritamente superior à de TODOS os outros golpes da mesma categoria** (ENGENHARIA_SOCIAL, TECNICO ou DOCUMENTAL). Se houver empate no maior valor, não liste os empatados. Exiba nome, categoria e severidade.

> Resultado esperado: **1 linha**



## 10. Autorrelacionamento (self join)

Liste as **incorporações** cadastradas no banco, mostrando o nome da instituição incorporada, o nome da incorporadora, o tipo da operação, o valor (que pode ser nulo) e a data. Ordene pela instituição incorporada.

> Resultado esperado: **18 linhas**



## 11. Taxa de devolução por vítima

Liste as vítimas com **no mínimo 10 contestações CONCLUÍDAS** e com **taxa de devolução total (DEVOLVIDO) estritamente maior que 70%**. Contestações em análise ou canceladas não contam. As parciais e as negadas fazem parte do total. Exiba devolvidas, total e percentual.

> Resultado esperado: **18 linhas**



## 12. NOT EXISTS (antijunção)

Localize as instituições que possuem **pelo menos uma conta**, mas cujas contas **NUNCA participaram de uma transação PIX**, nem como origem nem como destino.

> Resultado esperado: **7 linhas**



## 13. Subconsulta independente: média geral

Liste as transações **CONCLUÍDAS em outubro de 2026** cujo valor é superior à **média de valor de TODAS as transações concluídas** do banco. Exiba o identificador, o valor, a data e a média global (com duas casas decimais). Ordene pelo valor decrescente. A subconsulta deve ser independente da consulta principal.

> Resultado esperado: **309 linhas**



## 14. Subconsulta independente com IN

Liste, sem repetições, os clientes que **abriram pelo menos uma conta em Minas Gerais (MG)**, independentemente de onde moram ou de quem é o titular atual da conta. Use IN com uma subconsulta independente que retorne os identificadores dos clientes.

> Resultado esperado: **90 linhas**



## 15. Divisão relacional com UM único NOT EXISTS ⭐

Encontre os clientes que possuem atualmente contas em instituições que, juntas, oferecem **CADA serviço oferecido por instituições sediadas em SP**. Compare apenas com os serviços de SP, não com todos os serviços do banco. Use **apenas um** NOT EXISTS.

> Resultado esperado: **1 linha**

<details>
<summary>💡 Dica (abra só se travar)</summary>

Reescreva "o cliente cobre **todos** os serviços de SP" como uma frase com "**não existe** … que o cliente **não** tem". Cada "não" da frase vira um pedaço da consulta. Se você só pode usar um NOT EXISTS, que outro operador consegue expressar "não está na lista de serviços do cliente"?

</details>



### 15-B. Variação: contas envolvidas em todos os golpes de uma categoria

Encontre as contas que já foram identificadas em **TODOS os tipos de golpe da categoria ENGENHARIA_SOCIAL**. Use apenas um NOT EXISTS.

> Resultado esperado: **3 linhas**



### 15-C. Variação: investigados em todas as operações de um órgão

Encontre os clientes que foram investigados em **TODAS as investigações conduzidas pela POLICIA_FEDERAL**. Use apenas um NOT EXISTS.

> Resultado esperado: **1 linha**



### 15-D. Variação: o "todos" muda para cada cliente

Entre os clientes com **mais de um dispositivo**, encontre os que usaram **TODOS os seus próprios dispositivos** em transações **CONCLUÍDAS em outubro de 2026**. Use apenas um NOT EXISTS.

Atenção: a coluna `transacao_pix.id_dispositivo` pode ser nula.

> Resultado esperado: **70 linhas**



## 16. Autorrelacionamento e cadeias de incorporação

A partir da instituição **Órbita Digital**, liste as instituições que a absorveram em **uma ou duas incorporações consecutivas**. Exiba a instituição de origem, a instituição final e a quantidade de etapas. Use junções e UNION, sem recursão.

> Resultado esperado: **2 linhas**



## 17. Subconsulta independente com MAX

Localize os titulares que possuem atualmente pelo menos uma conta com o **MAIOR score de risco registrado em todo o banco**. Mostre o titular, o apelido da conta, a instituição e o score. Um mesmo titular pode aparecer mais de uma vez. Use uma subconsulta independente com MAX.

> Resultado esperado: **29 linhas**



## 18. Tabela derivada, GROUP BY e HAVING

Apresente os estados em que foram registradas **pelo menos 150 aberturas de conta**, mostrando o nome do estado, a quantidade de aberturas e a data da abertura mais recente. Calcule os totais numa **subconsulta no FROM** e depois junte o resultado à tabela de estados.

> Resultado esperado: **6 linhas**



## 19. ROLLUP, GROUPING e agregação hierárquica

Produza um relatório da **quantidade de contas com titular** por **estado do TITULAR** e **porte da instituição**. Inclua os subtotais por estado e o total geral, distinguindo os tipos de linha com GROUPING.

> Resultado esperado: **51 linhas**



## 20. Subconsulta independente e HAVING

Identifique os clientes que possuem atualmente **mais contas do que a MÉDIA de contas por cliente**, considerando nessa média também os clientes sem conta. Exiba identificador, nome e quantidade. Use uma subconsulta independente para calcular a média global e HAVING para filtrar os grupos.

> Resultado esperado: **261 linhas**


