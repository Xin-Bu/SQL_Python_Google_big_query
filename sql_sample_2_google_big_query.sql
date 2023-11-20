-- In this sample, we first create, fill, update, and delete the table,  
-- then interact with the table in Google Big Query (GBQ)
-- We'll have a total of 10 queries (from 11-20) in this sample. 

-- Query 11
-- We create an empty table named "product_summary" with three columns: 
-- year as integer, description as text, and sales as numeric.
-- We drop the table if it exists.

DROP TABLE IF EXISTS product_summary
CREATE TABLE product_summary
(year INTEGER,
description TEXT,
sales NUMERIC)

-- Query 12
-- We insert the following rows in our table"product_summary":
-- year description sales
-- 2014 BANANA Organic 176818.73
-- 2015 BANANA Organic 258541.96
-- 2014 AVOCADO Hass Organic 146480.34
-- 2014 ChickenBreastBoneless/Skinless 204630.90

INSERT INTO product_summary 
VALUES
('2014','BANANA Organic', '176818.73'),
('2015','BANANA Organic', '258541.96'),
('2014','AVOCADO Hass Organic', '146480.34'),
('2014','ChickenBreastBoneless/Skinless', '204630.90')
SELECT * FROM product_summary

-- Query 13
-- We update the year for the row containing the avocado sales to 2022.

UPDATE product_summary
SET year=2022
WHERE description='AVOCADO Hass Organic'
SELECT * FROM product_summary

-- Query 14
-- We delete the oldest banana row from the table.

DELETE FROM product_summary
WHERE description='BANANA Organic' AND year=2014
SELECT * FROM product_summary

-- The following queries are from GBQ

-- Query 15
-- This query returns departments and column named dept_spend, the sum of spending
-- in the department in 2015. We join the department name from departments so this 
-- query returns three columns.

SELECT
  dd.department AS Department,
  ds.dept_name AS Dept_name,
  SUM(dd.spend) AS Dept_spend
FROM
  `umt-msba.wedge_example.department_date` AS dd
LEFT JOIN
  `umt-msba.wedge_example.departments` AS ds
ON
  dd.department = ds.department
WHERE
  EXTRACT (YEAR FROM dd.date) =2015
GROUP BY
  dd.department, ds.dept_name
ORDER BY
  SUM(dd.spend) DESC

-- Query 16
-- This query returns five columns: card_no , year , month , spend , and items. 
-- The last two columns are the sum of the columns of the same name in the orginal
-- table. We filter the results to owner-year-month combinations between $750 and $1250,
-- ordered by spend in descending order, and only return the top 10 rows. 

SELECT card_no,
         EXTRACT(YEAR FROM date) AS year,
         EXTRACT(MONTH FROM date) AS month,
         SUM(spend) AS spend,
         SUM(items) AS items
FROM `umt-msba.wedge_example.owner_spend_date` 
GROUP BY card_no, year, month
HAVING spend>750 AND spend<1250
ORDER BY spend DESC
LIMIT 10

-- From queries 17 -20 we use tables from datasets from GBQ
-- Query 17
-- We query a series of tables using the wildcard operator. We write a query against the table
-- "umt-msba.transactions.transArchive_201001_201003" with the following columns:
-- 1. The total number of rows, which you can get with COUNT(*)
-- 2. The number of unique card numbers
-- 3. The total "spend". This value is in a field called total
-- 4. The number of unique product descriptions ( description )

SELECT COUNT(*) AS num_rows, 
       COUNT(DISTINCT(card_no)) AS card_no,
       SUM(total) AS total,
       COUNT(DISTINCT(description)) AS product_descriptions
FROM `umt-msba.transactions.transArchive_201001_201003` 

-- Query 18
-- We query across all transactions and report the results at the year level. 

SELECT EXTRACT(YEAR from datetime) AS year,
       COUNT(*) AS num_rows, 
       COUNT(DISTINCT(card_no)) AS card_no,
       SUM(total) AS total,
       COUNT(DISTINCT(description)) AS product_descriptions
FROM `umt-msba.transactions.transArchive_*`
GROUP BY year
ORDER BY year

-- Query 19
-- We write queries that produce the summary results. 
-- We write a query that returns spend, transactions, and items by year.

SELECT EXTRACT(YEAR from datetime) AS year,
   SUM(total) AS spend,
   COUNT(DISTINCT CONCAT(
     CAST (EXTRACT(date from datetime)AS STRING),
     CAST(register_no AS STRING),
     CAST(emp_no AS STRING),
     CAST(trans_no AS STRING)
   ) )AS trans,
   SUM(CASE WHEN trans_status= 'V' THEN -1
            WHEN trans_status= 'R' THEN -1
            ELSE 1 END) AS items
FROM `umt-msba.transactions.transArchive_*` 
WHERE trans_status IN (' ', 'V','R') AND
      department NOT IN (0,15)
GROUP BY year 
ORDER BY year

-- Query 20 (This query returns 39,312 rows)
-- We write a query that returns spend, transactions, and items by date and by hour.

SELECT EXTRACT(date from datetime) AS date,
       EXTRACT(hour from datetime) AS hour,
   SUM(total) AS spend,
   COUNT(DISTINCT CONCAT(
     CAST (EXTRACT(date from datetime)AS string),
     CAST(register_no AS string),
     CAST(emp_no AS string),
     CAST(trans_no AS string)
   ) )AS trans,
   SUM(CASE WHEN trans_status= 'V' THEN -1
            WHEN trans_status= 'R' THEN -1
            ELSE 1 END) AS items
FROM `umt-msba.transactions.transArchive_*` 
WHERE trans_status IN (' ', 'V','R') AND
      department NOT IN (0,15)
GROUP BY date, hour 
ORDER BY date, hour