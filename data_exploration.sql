/* First exploration of the database */
use magist;

/* 1. How many orders are there in the dataset? */
SELECT 
    COUNT(*)
FROM
    orders;

/* 2. Are orders actually delivered? */
SELECT 
    order_status, count(order_status)
FROM
    orders
GROUP BY order_status;

/* 3. Is Magist having user growth? */
SELECT 
    YEAR(order_purchase_timestamp) AS order_year,
    MONTH(order_purchase_timestamp) AS order_month,
    COUNT(order_id) AS order_count
FROM
    orders
GROUP BY order_year , order_month
ORDER BY order_count DESC;

/* 4. How many products are there on the products table? */
SELECT DISTINCT
    COUNT(*)
FROM
    products;

/* 5. Which are the categories with the most products? */
SELECT DISTINCT
    product_category_name, COUNT(product_id) AS prod_count
FROM
    products
GROUP BY product_category_name
ORDER BY prod_count DESC;
    
/* 6. How many of those products were present in actual transactions?
All of them were sold at least once! */
SELECT 
    COUNT(DISTINCT product_id)
FROM
    order_items;

/* 7. What’s the price for the most expensive and cheapest products? */
SELECT 
    MIN(price), MAX(price), AVG(price), STD(price)
FROM
    order_items;

/* 8. What are the highest and lowest payment values? */
SELECT 
    MIN(payment_value),
    MAX(payment_value),
    AVG(payment_value),
    STD(payment_value)
FROM
    order_payments;

