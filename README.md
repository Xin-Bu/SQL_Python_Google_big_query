# Selected SQL files
This is a collection of my selected SQL files.

This project includes three sets of SQL queries. The dataset has a total of 38,838 rows and five tables. The five tables are: date_hour, department_date, departments, owner_spend_date, and owners. The variables in each table are listed as below:


| table_name | variable_1 | variable_2 | variable_3 | variable_4 | variable_5 | 
| :---:   | :---: | :---: | :---: | :---: | :---: |    
| date_hour | date   | hour   | spend   | trans   | items   |
| department_date | date   | department   | spend   | trans   | items   |
| departments | department   | dept_name   |      |      |      |
| owner_spend_date | card_no   | date   | spend   | trans   | items   |
| owners | card_no | zip   | plus_2   | status   | date_joined   |

The code was written in SQLite. In addition, SQL in this project interacts with Google Big Query (GBQ) and Python in samples 2 and 3 respectively. 
