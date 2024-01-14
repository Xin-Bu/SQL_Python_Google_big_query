-- In this sample, we'll use SQL_Wedge.db database for the queries.  
-- Our SQL queries will later interact with Python code. 
-- We'll have a total of 10 queries (from 21-30) in this sample. 

-- Query 21
-- We calculate the total amount spent across all owners using the table "owner_spend_date".

 SELECT SUM(spend) AS total_spend
 FROM owner_spend_date

-- Query 22
-- We use the table "owner_spend_date" to find some specific shopping days. We set the following criteria:
-- 1.For owners who spent more than $10,000 in 2017, return the amount of their maximum spend in that year. 
-- 2.Return the columns card_no and spend.
-- 3.Order the results by spend, descending.
-- 4.Exclude card_no 3.

 FROM owner_spend_date
 SELECT card_no,
       SUBSTR(date,1,4) AS year,
       MAX(spend) AS spend
 FROM owner_spend_date 
 GROUP BY card_no, year
 HAVING SUM(spend)>10000 AND
        year='2017' AND 
      card_no != '3'
 ORDER BY spend DESC

-- Query 23
-- We use the table department_date and write a query that meet the following conditions:
-- 1.The department number is not 1 or 2.
-- 2.The spend on the day for the department is between $5,000 and $7,500.
-- 3.The month is May, June, July, or August.
-- 4.Order our results by spend, decreasing.

 SELECT *
 FROM department_date
 WHERE  department NOT IN ('1','2') AND
        spend < 7500 AND
        spend >5000 AND
        SUBSTR(date,6,2) IN ('05','06','07','08')
 ORDER BY spend DESC

-- Query 24
-- We use the tables date_hour and department_date and write a query that returns department spend during the busiest months. 
-- We use date_hour to determine the months with the four highest spends. 
-- Then we use department_date to return the department spend in departments during these months. 
-- Our query returns the year, the month, the total store spend (from date_hour), the department, and the department spend. 
-- We arrange our results ascending for year and month and descending for department spend. 
-- We limit our results to departments with over $200,000 spend in the month.

 WITH four_months AS(
    SELECT SUM(spend) AS total_spend, 
    SUBSTR(date,1,4) AS year,
            SUBSTR(date,6,2) AS month
    FROM date_hour
    GROUP BY month, year
    ORDER BY total_spend DESC
    LIMIT 4
    ),
dept_spend AS (
        SELECT SUBSTR(date,1,4) AS year, 
       SUBSTR(date,6,2) AS month,
       department,
       ROUND(SUM(spend),2) AS dept_spend
        FROM department_date
        GROUP BY department,month, year
     )
 SELECT ds.*, 
        fm.total_spend
 FROM dept_spend as ds
     INNER JOIN four_months AS fm ON fm.month=ds.month AND 
                                   fm.year=ds.year
 WHERE dept_spend > 200000
 ORDER BY year ASC, month ASC, dept_spend DESC

-- Query 25
-- This query answers the following question: for zip codes that have at least 100 owners,
-- what are the top five zip codes in terms of spend per transaction? 
-- We return the zip code, the number of owners in that zip code,
-- the average amount spent per owner, and the average spend per transaction.

 SELECT o.zip,
        COUNT(DISTINCT(osd.card_no)) AS num_owners,
        ROUND(SUM(osd.spend)/COUNT(DISTINCT(osd.card_no)),2) AS avg_spend_owner,
        ROUND(SUM(osd.spend)/SUM(osd.trans),2) AS avg_spend_trans
 FROM owner_spend_date AS osd
      LEFT JOIN owners AS o ON osd.card_no=o.card_no
 GROUP BY o.zip 
 HAVING COUNT(DISTINCT(o.card_no))>=100 AND
        o.zip!= "" AND 
        o.zip IS NOT NULL
 ORDER BY avg_spend_trans DESC
 
 -- Query 26
 -- We repeat query 25 but return the zip codes with the lowest spend per transaction. 

 SELECT o.zip,
        COUNT(DISTINCT(osd.card_no)) AS num_owners,
        ROUND(SUM(osd.spend)/COUNT(DISTINCT(osd.card_no)),2) AS avg_spend_owner,
        ROUND(SUM(osd.spend)/SUM(osd.trans),2) AS avg_spend_trans
 FROM owner_spend_date AS osd
      LEFT JOIN owners AS o ON osd.card_no=o.card_no
 GROUP BY o.zip 
 HAVING COUNT(DISTINCT(o.card_no))>=100 AND
        o.zip!= "" AND 
        o.zip IS NOT NULL
 ORDER BY avg_spend_trans 
 
-- Query 27.1
-- We write a query against the owners table that returns zip code, number of active owners,
-- number of inactive owners, and the fraction of owners who are active. 
-- We restrict our results to zip codes that have at least 50 owners. 
-- We order our results by the number of owners in the zip code.
-- This is the first solution.

SELECT zip,
       SUM(CASE WHEN status='ACTIVE' THEN 1 ELSE 0 END) AS active_owners,
       SUM(CASE WHEN status='INACTIVE' THEN 1 ELSE 0 END) AS inactive_owners,
       COUNT(DISTINCT(card_no)) AS num_owners,
       SUM(CASE WHEN status='ACTIVE' THEN 1 ELSE 0 END)/CAST(COUNT(DISTINCT(card_no)) AS REAL) AS faction_active
 FROM owners
 GROUP BY zip
 HAVING num_owners>=50 AND
        zip!= "" AND 
        zip IS NOT NULL
 ORDER BY num_owners DESC

-- Query 27.2
-- This is the second solution.

WITH cte_1 AS(
        SELECT zip, 
       COUNT(DISTINCT(card_no)) AS active_owners
        FROM owners
        WHERE status='ACTIVE'
        GROUP BY zip
    ),
cte_2 AS(SELECT zip, 
                COUNT(DISTINCT(card_no)) AS inactive_owners
         FROM owners
         WHERE status='INACTIVE'
         GROUP BY zip
    )
 SELECT o.zip, 
        cte_1.active_owners, 
        cte_2.inactive_owners, 
        COUNT(DISTINCT(o.card_no)) AS num_owners, 
        cte_1.active_owners/CAST(COUNT(DISTINCT(o.card_no)) AS REAL) AS faction_active
 FROM owners AS O
  INNER JOIN cte_1 ON o.zip=cte_1.zip
  INNER JOIN cte_2 ON o.zip=cte_2.zip
 GROUP BY o.zip
 HAVING num_owners>=50 AND
       o.zip!= "" AND 
       o.zip IS NOT NULL
 ORDER BY num_owners DESC

-- Queries 28-30 are written in Python.

-- Query 28 Create a table
-- We use the Python library sqlite3 and write code that opens a connection to a database called owner_prod.db. 
-- We create a cursor to that database. We use the cursor to create a table called owner_products in the database 
-- with the following columns and data types:
-- owner: integer
-- upc: integer
-- description: text
-- dept_name: text
-- spend: numeric
-- items: integer
-- trans: integer

-- Connect to a database
db= sqlite3.connect("owner_prod.db")
cur = db.cursor()
-- Create a table
cur.execute("DROP TABLE IF EXISTS owner_products")
cur.execute("""CREATE TABLE owner_products(
            owner integer,
            upc integer,
            description text,
            dept_name text,
            spend numeric,
            items integer,
            trans integer)""")

-- Query 29 Populate a table
-- We use a zip file called owner_products.zip , which has inside it owner_products.txt. 
-- We extract this file into the directory that holds our code. 
-- This tab-delimited text file has the same columns as the table we created in query 28.

owner_prod = []
with open("owner_products.txt",'r') as infile :
 next(infile)
 for line in infile :
  line = line.strip().split("\t")
  owner_prod.append(line)

cur.executemany("INSERT INTO owner_products values(?,?,?,?,?,?,?)", owner_prod)
db.commit()

-- Query 30 The description of the product
-- In Python, we execute a query against our new table that returns description (which is the
-- description of the product), dept_name, and total_spend for every product in a
-- department that has "groc" as a substring in the department name. The total spend is
-- the spend across all owners for that product. We order the results by total_spend descending.
-- We have our code iterate over the first 10 rows of the results and print them to the screen, then close the DB.

query = '''SELECT description,
                  dept_name,
                  ROUND(SUM(spend),2) AS total_spend
           FROM owner_products
           WHERE dept_name like '%groc%'
           GROUP BY description
           ORDER BY total_spend DESC
           LIMIT 10
           '''
results = cur.execute(query)
rows = results.fetchall()
for row in rows:
    print(row)