
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

/* Sales analysis of persons regarding to their top saled products with respect to their teams overall succes in 2020 Germany Berlin  */

WITH CTEQ 
AS(

	SELECT *,
		CAST(	COUNT(1) OVER (PARTITION BY Q3.[Sales Team]) AS decimal(10,4)) AS sales_team_member_count,
			SUM(Q3.tot_sales) OVER (PARTITION BY Q3.[Sales Team]) AS tot_sales_per_team
	FROM
		(SELECT Q2.[Name of Sales Rep],
				Q2.Country,
				Q2.City,
				Q2.top_saled_product,
				Q2.tot_sales,
				[Sales Team]
		FROM
			(SELECT DISTINCT [Name of Sales Rep],
							Country,
							City,
							FIRST_VALUE( [Product Name]) OVER (PARTITION BY [Name of Sales Rep] ORDER BY tot_sales DESC) AS top_saled_product,
							tot_sales
			FROM
				(SELECT Country,City,
						[Name of Sales Rep],
						SUM(Sales) OVER (PARTITION BY [Name of Sales Rep]) AS tot_sales,
						[Product Name]
				FROM PharmaData
				WHERE City='Berlin'AND Year='2020') AS Q1
				GROUP BY [Name of Sales Rep],Country,City,tot_sales,[Product Name]) AS Q2
		LEFT JOIN PharmaData PD
		ON
		Q2.[Name of Sales Rep]=PD.[Name of Sales Rep] AND Q2.top_saled_product=PD.[Product Name]
		AND Q2.City=PD.City AND Q2.Country=PD.Country) AS Q3
)
,CTEQ2 
AS
(
	SELECT DISTINCT [Sales Team],
					SUM(Sales) OVER (PARTITION BY [Sales Team],Country) AS tot2
	FROM PharmaData
	WHERE  Year='2020'
	GROUP BY [Sales Team],Sales,Country
)
SELECT DISTINCT Q4.[Name of Sales Rep],
		Q4.top_saled_product,
		PD.[Product Class],
		Q4.[Sales Team],
		CONVERT(decimal(10,4),(Q4.sales_team_member_count*Q4.rnk_team)/(Q4.rnk_person))*Q4.perc_over_country_team  AS f_rnk
FROM
	(SELECT CTEQ.[Name of Sales Rep],
				CTEQ.Country,
				CTEQ.City,
				CTEQ.top_saled_product,
				CTEQ.tot_sales,
				CTEQ.[Sales Team],
				CTEQ.sales_team_member_count,
				CTEQ.tot_sales_per_team,
				DENSE_RANK() OVER (PARTITION BY CTEQ.City,CTEQ.Country ORDER BY CTEQ.tot_sales DESC) AS rnk_person,
				(CTEQ.tot_sales_per_team/ CTEQ2.tot2)*100 AS perc_over_country_team,
				DENSE_RANK() OVER (ORDER BY tot_sales_per_team desc) AS rnk_team,
				ROW_NUMBER() OVER( PARTITION BY  [Name of Sales Rep] ORDER BY [Name of Sales Rep]  ) AS rn
	FROM CTEQ 
	LEFT JOIN CTEQ2 ON CTEQ.[Sales Team]=CTEQ2.[Sales Team] ) AS Q4 
	INNER JOIN PharmaData PD ON Q4.[Name of Sales Rep]=PD.[Name of Sales Rep] 
	AND Q4.top_saled_product=PD.[Product Name] 
	AND Q4.[Sales Team]=PD.[Sales Team]
WHERE Q4.rn=1
ORDER BY f_rnk DESC

