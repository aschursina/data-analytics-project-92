select count(c.customer_id ) as customers_count from customers c --общее количество покупателей из таблицы customers	

--АНАЛИЗ ОТДЕЛА ПРОДАЖ
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

--АНАЛИЗ ПОКУПАТЕЛЕЙ
--Отчет 1
SELECT
	CASE
		when age between 16 and 25 then '16-25'
		when age between 26 and 40 then '26-40'
		when age >= 41 then '40+'
	END as 	age_category,
	count(*) as age_count
FROM customers
WHERE age >=16
GROUP BY age_category
ORDER BY  1

--Отчет 2
SELECT
	to_char(s.sale_date, 'YYYY-MM') as selling_month,
	count(distinct(s.customer_id)) as total_customers,
	sum(s.quantity * p.price) as income
FROM sales s join products p on s.product_id=p.product_id
GROUP BY selling_month
ORDER BY selling_month

--Отчет 3
WITH first_sale AS (
	SELECT
		customer_id,
		min(sale_date) as first_sale,
		min(sales_person_id) as sales_person_id
	FROM sales 
	GROUP BY customer_id
),--поиск первой покупки
zero_price AS (
	SELECT 
		distinct(s.customer_id) as customer_id
	FROM sales s 
	JOIN products p on s.product_id =p.product_id
	WHERE p.price=0
)-поиск клиентов с покупкой по акции
SELECT
	CONCAT(c.last_name, ' ', c.first_name) AS customer,
	fs.first_sale as sale_date, 
	CONCAT(e.last_name, ' ', e.first_name) AS seller
FROM first_sale fs
JOIN zero_price z on fs.customer_id =z.customer_id
JOIN employees e ON fs.sales_person_id = e.employee_id
JOIN customers c  ON fs.customer_id = c.customer_id
ORDER BY fs.customer_id 

