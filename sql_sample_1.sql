-- In this sample, we will use the tables "owner_spend_date" and "owners". 
-- We'll have a total of 10 queries (from 11-20) in this sample. 

-- Query 1
-- In this query, we use the table "owner_spend_date" to create a temporary table
-- "owner_year_month" that has the following columns: card_no, year, month, spend,
-- and items. The last two columns are the sum of the columns of the same name in the
-- original table. 

DROP TABLE IF EXISTS owner_year_month;
CREATE TEMPORARY TABLE owner_year_month AS
  SELECT card_no,
	     SUBSTR(date, 1,4) AS year,
	     SUBSTR(date, 6,2) AS month,
	     SUM(spend) AS spend,
	     SUM(items) AS items
  FROM owner_spend_date
  GROUP BY card_no, year, month

-- Query 2
-- This query returns year, month, and the top-five highest spend with the total spend for
-- the five month-year combos.

SELECT year, month, SUM(spend) AS total_spend
FROM owner_year_month
GROUP BY year, month
ORDER BY total_spend DESC
LIMIT 5 

-- Query 3 
-- Using the temporary table "owner_year_month" and the "owners" table, we return the average
-- spend by month across all years for owners who lived in the 55405 zip code. 

SELECT oym.month,
       ROUND(SUM(oym.spend)/COUNT(oym. month),2) AS avg_monthly_spend
FROM owner_year_month AS oym, owners AS o
WHERE oym.card_no = o.card_no AND o.card_no IN (
      SELECT card_no
      FROM owners
      WHERE zip=55405)
GROUP BY oym.month
ORDER BY oym.month
		
-- Query 4 
-- This query returns zip code and total sales for the three zip codes with the highest total sales. 

SELECT o.zip, ROUND(sum(oym.spend),2) AS total_sales
FROM owner_year_month AS oym 
LEFT JOIN owners AS o ON oym.card_no=o.card_no
WHERE o.zip IS NOT NULL
GROUP BY o.zip
ORDER BY total_sales DESC
LIMIT 3

-- Query 5
-- Using the temporary table "owner_year_month" and the "owners" table, we return the average
-- spend by month across all years for owners who lived in the 55405 zip code, including four columns in 
-- our output. We include month, as well as one column of average sales for each of the zip codes we found 
-- from the previous query. We name the results "avg_spend_55405". Additionally, we joint two CTEs to append
-- the columns holding the average sales for the two zips that are not 55405. 

WITH cte_1 AS (
     SELECT oym.card_no, oym.month,
	   ROUND(SUM(oym.spend)/COUNT(oym. month),2) AS avg_spend_55405
	FROM owner_year_month AS oym, owners AS o
	WHERE oym.card_no = o.card_no AND o.card_no IN (
		SELECT card_no
		FROM owners 
		WHERE zip=55405)
	GROUP BY oym.card_no,oym.month
	ORDER BY oym.card_no,oym.month
	 ),
cte_2 AS (
     SELECT oym.card_no, oym.month,
	   ROUND(SUM(oym.spend)/COUNT(oym. month),2) AS avg_spend_55408
	 FROM owner_year_month AS oym, owners AS o
	 WHERE oym.card_no = o.card_no AND o.card_no IN (
		SELECT card_no
		FROM owners 
		WHERE zip=55408)
	 GROUP BY oym.card_no,oym.month
	 ORDER BY oym.card_no,oym.month
	 ),
cte_3 AS (
     SELECT oym.card_no, oym.month,
	   ROUND(SUM(oym.spend)/COUNT(oym. month),2) AS avg_spend_55403
	 FROM owner_year_month AS oym, owners AS o
	 WHERE oym.card_no = o.card_no AND o.card_no IN (
		SELECT card_no
		FROM owners 
		WHERE zip=55403)
	 GROUP BY oym.card_no,oym.month
	 ORDER BY oym.card_no,oym.month
	 )
SELECT oym.card_no, oym.month, cte_1.avg_spend_55405, cte_2.avg_spend_55408, cte_3.avg_spend_55403
owner_year_month AS oym, owners AS o
INNER JOIN cte_1 ON oym.card_no=cte_1.card_no
INNER JOIN cte_2 ON oym.card_no=cte_2.card_no
INNER JOIN cte_3 ON oym.card_no=cte_3.card_no
GROUP BY oym.card_no,month

-- Query 6 
-- We add a column named total_spend which holds the total spend across all years and months. We use 
-- a CTE to calculate the total sales and Join that to our previous query. We delete the temporary table 
-- if it exists. 

DROP TABLE IF EXISTS owner_year_month_2
CREATE TEMPORARY TABLE owner_year_month_2 AS
WITH cte_4 AS(
     SELECT card_no,
	  SUM(spend) AS total_sales
        FROM owner_year_month 
        GROUP BY card_no
	 )
SELECT oym.card_no, oym.year, oym.month, oym.spend, oym.items, cte_4.total_sales 
FROM owner_year_month AS oym
INNER JOIN cte_4 ON oym.card_no = cte_4.card_no

SELECT COUNT(DISTINCT(card_no)) AS owners,
	   COUNT(DISTINCT(year)) AS years,
	   COUNT(DISTINCT(month)) AS months,
	   ROUND(AVG(spend),2) AS avg_spend,
	   ROUND(AVG(items),1) AS avg_items,
	   ROUND(SUM(spend)/SUM(items),2) AS avg_item_price
FROM owner_year_month_2

-- Query 7
-- We use "owner_spend_date" table and create a view with total amount spent by owner, the average spend per
-- transaction, number of dates they have shopped, the number of transactions they have, and the date of their 
-- last visit. Our view is named "vw_owner_recent"

 DROP VIEW IF EXISTS vw_owner_recent;
 CREATE VIEW vw_owner_recent AS
   SELECT card_no,
		  SUM(spend) AS total_spend,
       	  SUM(spend)/SUM(trans) AS avg_spend_trans,
		  COUNT(DISTINCT(date)) AS num__shopping_days,
		  SUM(trans) AS total_trans,
		  MAX(date) AS last_visit
   FROM owner_spend_date
   GROUP BY card_no

SELECT COUNT(DISTINCT card_no) AS owners,
       ROUND(SUM(total_spend)/1000,1) AS spend_k
FROM vw_owner_recent
WHERE 5 < total_trans AND
      total_trans < 25 AND
      SUBSTR(last_visit,1,4) IN ('2016','2017')
 
-- Query 8 
-- We create a table in our database. We build our view in the table called "owner_recent" and add an additional column. 
-- The new column called last_spend is the amount spent on the date of that last visit. 

DROP TABLE IF EXISTS owner_recent;
CREATE TEMPORARY TABLE owner_recent AS
SELECT vor.*,
       osd.spend AS last_spend
FROM vw_owner_recent AS vor  
LEFT JOIN owner_spend_date AS osd
     ON (vor.card_no= osd.card_no AND vor.last_visit=osd.date )
GROUP BY osd.card_no

SELECT *
FROM owner_recent
WHERE card_no = "18736"

SELECT *
FROM vw_owner_recent
WHERE card_no = "18736";	

--1. What is the time difference between the two versions of the query?
--The first query took 17ms and the second 2922ms. 
--2. Why do you think this difference exists?
--The difference exists because the first table is a temporary table and the second is a view table. 

-- Query 9
-- This query returns the columns from "owner_recent" for owners who meet the following criteria:
-- 1. Their last spend was less than half their average spend.
-- 2. Their total spend was at least $5,000.
-- 3. They have at least 270 shopping dates.
-- 4. Their last visit was at least 60 days before 2017-01-31.
-- 5. Their last spend was greater than $10
-- The results are ordered by the drop in spend, from the largest drop to smallest, and total spend. 

SELECT *
FROM  owner_recent
WHERE (last_spend - avg_spend_trans/2) <0 AND
      total_spend >5000 AND
      num__shopping_days > 270 AND
      last_visit< DATE('2017-01-31', '-60 day') AND
      last_spend > 10
GROUP BY card_no
ORDER BY (last_spend - avg_spend_trans/2) ASC
       
-- Query 10
-- This query returns the columns from "owner_recent" for owners who meet the following criteria:
-- 1. The have non-null, non-blank zips and they do not live in the Wedge or adjacent zip codes.
-- 2. Their last spend was less than half their average spend.
-- 3. Their total spend was at least $5,000.
-- 4. They have at least 100 shopping dates.
-- 5. Their last visit was at least 60 days before 2017-01-31.
-- 6. Their last visit was over $10
-- We include the owner's zip code in our query results. The results are ordered by the drop in spend, 
-- from the largest drop to smallest, and total spend.

SELECT o.zip,
       orc.card_no,
       (orc.last_spend - orc.total_spend/orc.num__shopping_days/2) AS drop_in_spend,
       orc.total_spend,
       orc.num__shopping_days AS shopping_dates,
       orc.last_visit,
       orc.last_spend 
FROM owner_recent AS orc 
LEFT JOIN owners AS o ON orc.card_no=o.card_no
GROUP BY o.zip, orc.card_no  
HAVING 	o.zip NOT IN (55405, 55442, 55416, 55408, 55404, 55403)AND
		o.zip IS NOT NULL AND 
		o.zip!=''AND
	  	drop_in_spend <0 AND
		orc.total_spend >5000 AND
		shopping_dates > 100 AND
	 	last_visit< DATE('2017-01-31', '-60 day') AND
		last_spend > 10
ORDER BY drop_in_spend ASC
