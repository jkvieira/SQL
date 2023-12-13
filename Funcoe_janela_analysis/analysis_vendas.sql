-- criação do schema ------------------------------------------------------------------------------------------------
create database if not exists teste;

use teste;

-- criação da tabela e inserção dos dados  ---------------------------------------------------------------------------
create table vendas_regiao (
    data_venda DATE,
    regiao VARCHAR(50),
    produto VARCHAR(50),
    quantidade INT,
    receita DECIMAL(10, 2)
);

insert into vendas_regiao values
    ('2023-01-01', 'Norte', 'Produto_A', 10, 150.00),
    ('2023-01-02', 'Sul', 'Produto_B', 8, 120.00),
    ('2023-01-03', 'Norte', 'Produto_A', 15, 200.00),
    ('2023-01-04', 'Sul', 'Produto_C', 5, 75.00),
    ('2023-01-05', 'Norte', 'Produto_B', 12, 180.00),
    ('2023-01-06', 'Sul', 'Produto_A', 8, 120.00),
    ('2023-01-07', 'Norte', 'Produto_C', 10, 150.00),
    ('2023-01-08', 'Sul', 'Produto_A', 20, 250.00),
    ('2023-01-09', 'Norte', 'Produto_B', 6, 90.00),
    ('2023-01-10', 'Sul', 'Produto_C', 15, 200.00);

insert into vendas_regiao values
    ('2023-02-01', 'Norte', 'Produto_A', 10, 150.00),
    ('2023-02-02', 'Sul', 'Produto_B', 8, 120.00),
    ('2023-02-03', 'Norte', 'Produto_A', 10, 125.00),
    ('2023-02-04', 'Sul', 'Produto_C', 5, 75.00),
    ('2023-02-05', 'Norte', 'Produto_B', 10, 150.00),
    ('2023-02-06', 'Sul', 'Produto_A', 8, 120.00),
    ('2023-02-07', 'Norte', 'Produto_C', 10, 150.00),
    ('2023-02-08', 'Sul', 'Produto_A', 10, 125.00),
    ('2023-02-09', 'Norte', 'Produto_B', 4, 70.00),
    ('2023-02-10', 'Sul', 'Produto_C', 13, 150.00);

insert into vendas_regiao values
    ('2023-03-01', 'Norte', 'Produto_A', 20, 250.00),
    ('2023-03-02', 'Sul', 'Produto_B', 10, 150.00),
    ('2023-03-03', 'Norte', 'Produto_A', 10, 125.00),
    ('2023-03-04', 'Sul', 'Produto_C', 10, 155.00),
    ('2023-03-05', 'Norte', 'Produto_B', 12, 180.00),
    ('2023-03-06', 'Sul', 'Produto_A', 12, 160.00),
    ('2023-03-07', 'Norte', 'Produto_C', 12, 180.00),
    ('2023-03-08', 'Sul', 'Produto_A', 10, 125.00),
    ('2023-03-09', 'Norte', 'Produto_B', 10, 140.00),
    ('2023-03-10', 'Sul', 'Produto_C', 14, 200.00);

-- consultas usando funções de janelas -------------------------------------------------------------------------------

Select * from vendas_regiao;

-- ** Média Acumulativa por Região: **

/*Calcule a média acumulativa de receita por região para cada produto ao longo do tempo. Ordene os
 resultados por região, produto e data.*/

select 
   data_venda,
   regiao,
   produto,
   receita,
   round(avg(receita) over (partition by regiao,produto order by data_venda), 2) as media_acum_receita
from 
   vendas_regiao
order by 
    regiao, produto, data_venda;

-- **Classificação de Vendas por Região:**

/*Atribua uma classificação às vendas de cada produto em cada região com base na receita total. 
Mostre apenas as três vendas mais lucrativas por região.*/

with rank_produtos_regiao as (
select
   regiao,
   produto,
   sum(receita) as receita_total,
   dense_rank() over (partition by regiao order by sum(receita) desc) as rank_receita
from 
    vendas_regiao
group by 
    regiao, produto
)
select 
   regiao,
   produto,
   receita_total,
   rank_receita
from 
   rank_produtos_regiao
where 
   rank_receita <= 3;
   
-- **Variação Percentual na Quantidade Vendida:**

/*Calcule a variação percentual na quantidade vendida de cada produto em relação ao mês anterior para 
cada região.*/

with quantidade_mensal_tb as (
   select
        regiao,
        produto,
        month(data_venda) as mes,
        SUM(quantidade) as quantidade_mensal
    FROM 
       vendas_regiao
    group by 
       regiao, produto, mes
    order by 
       regiao, produto, mes
)
select
    regiao,
    produto,
    mes,
    quantidade_mensal,
    lag(quantidade_mensal,1,0) over (partition by regiao,produto order by mes) as quantidade_mes_anterior, 
	round( 
      case
          when lag(quantidade_mensal,1,0) over (partition by regiao,produto order by mes) <> 0 
          then ((quantidade_mensal - lag(quantidade_mensal,1,0) over (partition by regiao,produto order by mes)) / lag(quantidade_mensal,1,0) over (partition by regiao,produto order by mes))*100 
          else 0
		end, 1) as variacao_percentual_quantidade 
 from 
     quantidade_mensal_tb;


-- **Total de Receita Acumulativa por Produto:**

/*Calcule o total de receita acumulativa para cada produto, considerando todas as regiões. Ordene os resultados
 por produto e data.*/
 
select 
    data_venda,
    regiao,
    produto,
    sum(receita) over (partition by produto order by data_venda) as receita_acumulativa
from 
    vendas_regiao
order by 
    produto, data_venda;