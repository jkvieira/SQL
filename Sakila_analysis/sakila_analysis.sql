/* Script sakila
   Análises de treino e teste sobre o banco de dados nativo do MySQL sakila. 
*/
USE sakila;

-- 1- Recuperação de Informações Gerais:

 -- Obtenha uma lista de todos os filmes no banco de dados, exibindo o título e a categoria.

select
     f.title,
     c.name
from
     film f 
inner join 
     film_category fc on f.film_id = fc.film_id
inner join  
     category c on fc.category_id = c.category_id;
  
  -- Classificação dos filmes
 /*
  A empresa está interessada em conhecer a classificação média dos filmes alugados, mas com uma 
  diferenciação entre "High" (Alta), "Medium" (Média) e "Low" (Baixa) com base na seguinte tabela:

"High" para filmes com classificação superior a 8.
"Medium" para filmes com classificação entre 5 e 8 (inclusive).
"Low" para filmes com classificação inferior a 5.
*/

select
   avg(rating) as classificacao_media,
   case
      when avg(rating) > 8 then "High"
      when avg(rating) >= 5 and avg(rating) <= 8 then "Medium"
      else "Low"
   end as classificacao
   from
     film;  

-- 2- Clientes e Aluguéis:

 -- Qual é o nome do cliente que fez o maior número de aluguéis?
 
 select 
   c.first_name as nome,
   c.last_name as sobrenome,
   count(*) as total_alugueis
from
   rental r
inner join 
    customer c on c.customer_id = r.customer_id
group by 
   r.customer_id
order by 
   total_alugueis desc;

-- Resposta: O cliente com o maior número de aluguéis é Eleanor Hunt.
 
-- Existe algum cliente cadastrado que não alugou filmes?
select
  c.customer_id
from 
   customer c 
left join 
    rental r on r.customer_id = c.customer_id
where 
    r.customer_id is null;

-- Resposta: Não! Todos os clientes fizeram algum aluguel.

-- Liste os 2 clientes que mais alugaram filmes em cada categoria, se tiver algum empate 
-- use algum critério de desempate.
   
with rank_client_category as (
 select 
   c.name as category,
   r.customer_id as id_cliente,
   cu.first_name as nome,
   cu.last_name as sobrenome,
   rank() over (partition by c.category_id order by count(*) desc, r.customer_id) as rank_cli,
   count(*) as total_alugueis
   from 
         rental r
	inner join 
         customer cu on r.customer_id = cu.customer_id
    inner join
        inventory i ON r.inventory_id = i.inventory_id
    inner join
        film f ON i.film_id = f.film_id
    inner join
        film_category fc ON f.film_id = fc.film_id
    inner join
        category c ON fc.category_id = c.category_id
	group by 
        c.category_id, r.customer_id
)
select 
   category,
   nome,
   sobrenome, 
   total_alugueis,
   rank_cli 
from 
  rank_client_category
where 
   rank_cli <= 2 
order by 
    category,rank_cli
;  


-- 3- Análise de Ator:

  -- Quais são os três atores que mais participaram em filmes?

select 
    fa.actor_id,
    a.first_name,
    a.last_name,
    count(*) as total_filmes
 from
    film_actor fa
 inner join 
	actor a on fa.actor_id = a.actor_id
 group by 
    actor_id
 order by 
    total_filmes desc;

-- Resposta: Os três atores são: GINA DEGENERES, WALTER	TORN e MARY KEITEL.

-- 4- Categorias Populares:

 -- Liste as categorias de filmes ordenadas pela quantidade total de aluguéis.

select 
    c.name,
    count(*) as total_alugueis
from
    inventory i
inner join 
    rental r on r.inventory_id = i.inventory_id
inner join 
    film f on f.film_id = i.film_id
inner join 
     film_category fc on f.film_id = fc.film_id
inner join 
	category c on fc.category_id = c.category_id
group by
     c.name
order by  
     total_alugueis desc;

-- 5-Frequência de Aluguéis ao Longo do Tempo:

   -- Como a quantidade de aluguéis varia ao longo do tempo? Apresente um gráfico ou tabela
   -- com a quantidade de aluguéis por mês/ano.
  
  SELECT
    DATE_FORMAT(rental_date, '%m-%Y') AS mes_ano,
    COUNT(*) AS total_alugueis
FROM
    rental
GROUP BY
    mes_ano
ORDER BY
    mes_ano;
   
-- 2- Valor Médio dos Aluguéis:

 -- Qual é o valor médio dos aluguéis para cada categoria de filme?

select 
  c.name as categoria,
  round(avg(p.amount),2) as valor_medio
from
   rental r
inner join 
   inventory i on r.inventory_id = i.inventory_id
inner join 
    film f on f.film_id=i.film_id
inner join 
    film_category fc on f.film_id = fc.film_id
inner join  
	category c on fc.category_id = c.category_id
inner join 
	payment p on r.rental_id = p.rental_id
group by
   categoria
order by 
    valor_medio desc;
    
-- Resposta: O valor médio para cada categoria é dado pela tabela abaixo:
/*
Categoria   valor_médio
Action	      3.94
Animation	  3.99
Children	  3.87
Classics	  3.88
Comedy	      4.66
Documentary	  4.02
Drama	      4.33
Family	      3.86
Foreign	      4.13
Games	      4.42
Horror	      4.40
Music	      4.12
New	          4.63
Sci-Fi	      4.32
Sports	      4.51
Travel	      4.24
*/

-- 6- Filmes de Maior Sucesso:

  -- Liste os cinco filmes mais alugados de cada categoria
  
WITH RankedFilms AS (
    select
	  f.film_id,
      c.name as categoria,
      f.title as titulo,
      rank() over (partition by fc.category_id order by count(*) desc) as rankFilme,
      count(*) as total_alugueis
    from
        rental r
    inner join
        inventory i ON r.inventory_id = i.inventory_id
    inner join
        film f ON i.film_id = f.film_id
    inner join
        film_category fc ON f.film_id = fc.film_id
    inner join
        category c ON fc.category_id = c.category_id
   group by 
        fc.category_id, f.film_id
)
select 
   categoria,
   titulo,
   total_alugueis
 from 
    rankedFilms
 where 
    rankFilme <= 5
 order by
    categoria, rankfilme;

-- 7 - Duração Média dos Filmes por Categoria:
  
  -- Qual é a duração média dos filmes em cada categoria?

select
    c.name as categoria,
    round(avg(f.length), 2) as duracao_media
from 
    film f
inner join
    film_category fc on f.film_id = fc.film_id
inner join 
    category c on c.category_id = fc.category_id
group by
    categoria
order by
	duracao_media desc;

-- Resposta: A duração média dos filmes de cada categoria é dada na tabela abaixo:
/*
Categoria   Duração média
Travel	     113.32
Sports	     128.20
Sci-Fi	     108.20
New	         111.13
Music      	 113.65
Horror	     112.48
Games	     127.84
Foreign  	 121.70
Family		 114.78
Drama		 120.84
Documentary	 108.75
Comedy		 115.83
Classics	 111.67
Children	 109.80
Animation	 111.02
Action	     111.61
*/

-- 8- Padrões de Aluguel:
   -- Existe algum padrão nos horários/dias em que os clientes mais frequentemente alugam filmes?

-- Análise dias da semana
select
  dayofweek(rental_date) as dia_da_semana,
  count(*) as total_alugueis
from
   rental
group by 
   dia_da_semana
order by 
   total_alugueis desc;

-- Respota: O dia da semana com maior número de aluguéis é a terça-feira.

-- Análise hora do aluguel do filme
select
    extract(hour from rental_date) as hora_aluguel,
    count(*) as total_alugueis
from
    rental
group by
    hora_aluguel
order by
    total_alugueis  desc;

-- Resposta: O horário com maior procura de filmes foi as 15:00 horas.

  -- Existe algum padrão sazonal mensal ou anual? Por exemplo, mais aluguéis em meses específicos do ano.
select
  month(rental_date) as mes,
  year(rental_date) as ano,
  count(*) as total_alugueis
from
    rental
group by 
	ano,mes
order by 
    mes;

-- Resposta: Em 2006 só houveram vendas em fevereiro. Já em 2005 o mês que mais houve vendas foi em maio. 

