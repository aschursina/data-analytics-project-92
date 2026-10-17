select count(c.customer_id ) as customers_count from customers c --общее количество покупателей из таблицы customers	

--Отчет 1
WITH sellers AS (
    SELECT 
        s.sales_person_id, 
        CONCAT(e.last_name, ' ', e.first_name) AS seller, --склеивание ФИ
        SUM(s.quantity * p.price) as income, --выручка
        COUNT(s.sales_id) AS operations --количество сделок
    FROM sales s 
    JOIN employees e ON s.sales_person_id = e.employee_id
    JOIN products p ON s.product_id = p.product_id 
    GROUP BY s.sales_person_id, e.last_name, e.first_name
)  --Получение данных для отчета 
SELECT 
    s.seller,
    s.operations,
    round(s.income) as income
FROM sellers s 
ORDER BY s.income DESC
LIMIT 10

--Отчет 2
WITH sellers AS (
    SELECT 
        s.sales_person_id, 
        CONCAT(e.last_name, ' ', e.first_name) AS seller, 
        SUM(s.quantity * p.price) as income,
        COUNT(s.sales_id) AS operations,
        SUM(s.quantity * p.price)  / COUNT(s.sales_id) as avg_income, --среднее за сделку продавца
    	avg(SUM(s.quantity * p.price) / COUNT(s.sales_id)) over() as company_avg_income --среднее по сделкам всех продавцов
    FROM sales s 
    JOIN employees e ON s.sales_person_id = e.employee_id
    JOIN products p ON s.product_id = p.product_id 
    GROUP BY s.sales_person_id, e.last_name, e.first_name
) --Получение данных для отчета 
SELECT 
    s.seller,
    round(s.avg_income) as average_income
from sellers s
where s.avg_income < s.company_avg_income --поиск средней выручки за сделку, которая меньше средней выручки за сделку по всем продавцам
order by s.avg_income 

--Отчет 3
WITH income_daily AS (
    SELECT 
        CONCAT(e.last_name, ' ', e.first_name) AS seller, --склеивание ФИ
        s.sale_date::date as sale_date,
        SUM(s.quantity * p.price) as income --выручка    
    FROM sales s 
    JOIN employees e ON s.sales_person_id = e.employee_id
    JOIN products p ON s.product_id = p.product_id 
    GROUP BY e.last_name, e.first_name, s.sale_date
)  --получение данных о выручке по дате
SELECT 
    i.seller,
    trim(to_char(i.sale_date, 'Day' )) as day_of_week, --получение дня недели из даты
    round(i.income) as income
FROM  income_daily i 
ORDER by extract(dow from i.sale_date), i.seller --получение номера дня недели, 0 - sunday 
