
/*Percentage Sale of Antibiotics for Pharmacy in 2017,2018,2019,2020 */
WITH CTE_1 (Yýl,Seasons,Tot_sales,Tot_q)
as
(
SELECT DISTINCT Year,
case
	when Month='January' or  Month='February' or  Month='March' then 'Winter'
	when Month='April' or  Month='May' or Month='June' then  'Spring'
	when Month='July' or  Month='August' or  Month='September' then  'Summer'
	when Month='October' or  Month='November' or  Month='December' then  'Fall'
end as Seasons,

SUM(cast( sales as float)) as Tot_sales, sum(quantity) as Tot_q
FROM DOGUKAN.DBO.PharmaData
where [Product Class]='Antibiotics' 
		and Channel='Pharmacy' 
		and [Sub-channel]='Retail' 
		and Quantity > 0
GROUP BY YEAR ,Month


)
select DISTINCT  Yýl,sum(Tot_q) /(select sum(quantity) from DOGUKAN..Pharmadata where Quantity>0 )*100 as Perc
from CTE_1

group by Yýl
order by 2 desc
go

/* Total saled uints over year */
select distinct Year , sum(cast (Quantity as int))  over (Partition By Year) as Quantitty
from DOGUKAN..PharmaData
where Quantity > 0
--where Year='2019' or Year='2020'
--Group By [Product Class],Year
order by 1,2 desc

go
/* Percentage of Products per Year in Germany */
WITH CTE_2 (Yýl,Product_type,Tot_sales,Tot_q)
as
	( SELECT DISTINCT
	Year,
	[Product Class],
	SUM(cast( sales as float)) as Tot_sales, 
	sum(quantity) as Tot_q

	FROM DOGUKAN.DBO.PharmaData

	where Country='Germany'

	GROUP BY YEAR , [Product Class]
)
select DISTINCT  Yýl,Product_type,
sum(Tot_q) /(select sum(quantity) 
from DOGUKAN..Pharmadata where Quantity>0 )*100 as Perc
from CTE_2
group by Product_type,Yýl
order by 1 asc,3 desc
go


/* Top 5 Products Sold in Germany per Year and Percantage  */
WITH CTE_3 (Yýl,Product_name,Product_type,Tot_sales,Tot_q)
as
(	SELECT 
	Year,
	[Product Name],[Product Class],
	SUM(cast( Quantity as float)) as Tot_q, 
	sum(quantity) as Tot_q
	FROM DOGUKAN.DBO.PharmaData
	where Country='Germany'
	GROUP BY YEAR , [Product Name],[Product Class]
)
,CTE_123
as
(
	select  Yýl,Product_name,Product_type,
		Rank() over (Partition by yýl order by ( Tot_q /
		(select sum(quantity) 
		from DOGUKAN..Pharmadata where Quantity>0  * 100))desc)  as Ranking,
		Tot_q / 
		(select sum(quantity) 
		from DOGUKAN..Pharmadata where Quantity>0 ) * 100 as Perc
	from CTE_3
	group by Product_type,Yýl,Product_name,Tot_q
)
SELECT Yýl,Product_name,Product_type,Ranking,perc 
FROM CTE_123
WHERE Ranking IN (1,2,3,4,5)


/*  Top 5 Product name and product class per SalesTeam over Sales  */
with cte_5 (prod_name,prod_class,sumt,sales_team,ranking)
as
(
	select distinct [Product Name],[product class], sum(sales) over (partition by [product Name],[sales Team] order by [sales Team]) as sumt,[Sales Team],
	rank() over (partition by [Sales Team] order by Sum(sales))
	from PharmaData
	group by [Product Name],Sales,Month,[Sales Team],[Product Class]
)
select sales_team,prod_class,prod_name,sumt,ranking
from cte_5 
where ranking in (1,2,3,4,5)
order by 5 asc,sumt desc




/* Total sales of each team with max prdouct they sold  */
WITH CTE_12 (prod,sale_prod,team,category)
AS
(
	SELECT DISTINCT [Product Name],SUM(Sales) as tot_sales_prod,[Sales Team],[Product Class]
	FROM PharmaData
	group by [Product Name],[Sales Team],[Product Class]
	
	
)
,CTE_13 (Product,SalesTeam,TotalSales,Ranking,Product_Class)
AS
( 
		SELECT prod,
				team,
				sale_prod,
				rank()over (partition by team order by sale_prod) as Ranking,
				category
		from CTE_12

)

select SalesTeam,TotalSales,Product,Product_Class 
from CTE_13
where Ranking=1
