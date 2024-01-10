use magist;

/* Answering the business question: Is Magist good enough in delivering Eniac's products to the customers? */

/* What’s the average time between the order being placed and the product being delivered? */
SELECT 
    order_purchase_timestamp AS ordered,
    order_delivered_customer_date AS delivered,
    TIMESTAMPDIFF(HOUR,
        order_purchase_timestamp,
        order_delivered_customer_date) AS delivery_hours
FROM
    orders;

/* Country-wide average delivery time is 12 days! */
SELECT 
    AVG(TIMESTAMPDIFF(HOUR,
        order_purchase_timestamp,
        order_delivered_customer_date)) AS avg_duration_hours,
    AVG(TIMESTAMPDIFF(DAY,
        order_purchase_timestamp,
        order_delivered_customer_date)) AS avg_duration_days,
    MIN(YEAR(order_purchase_timestamp)) AS start_year,
    MAX(YEAR(order_purchase_timestamp)) AS last_year
FROM
    orders;
    
/* Delivery speed improved in 2018! */
SELECT 
    DATE_FORMAT(order_purchase_timestamp, '%Y %M') AS year_mon,
    AVG(TIMESTAMPDIFF(HOUR,
        order_purchase_timestamp,
        order_delivered_customer_date)) AS avg_duration_hours,
    AVG(TIMESTAMPDIFF(DAY,
        order_purchase_timestamp,
        order_delivered_customer_date)) AS avg_duration_days,
    MIN(TIMESTAMPDIFF(DAY,
        order_purchase_timestamp,
        order_delivered_customer_date)) AS min_duration_days,
    MAX(TIMESTAMPDIFF(DAY,
        order_purchase_timestamp,
        order_delivered_customer_date)) AS max_duration_days
FROM
    orders
GROUP BY year_mon
ORDER BY year_mon;


/* Delivery times are massively different when compared on a state level!
Long in all cases - quickest state average is ~8 days! */
SELECT 
    g.state,
    AVG(TIMESTAMPDIFF(HOUR,
        order_purchase_timestamp,
        order_delivered_customer_date)) AS avg_duration_hours,
    AVG(TIMESTAMPDIFF(DAY,
        order_purchase_timestamp,
        order_delivered_customer_date)) AS avg_duration_days,
	min(TIMESTAMPDIFF(day,
        order_purchase_timestamp,
        order_delivered_customer_date)) AS min_duration_days,
	max(TIMESTAMPDIFF(DAY,
        order_purchase_timestamp,
        order_delivered_customer_date)) AS max_duration_days
FROM
    orders AS o
        LEFT JOIN
    customers AS c ON o.customer_id = c.customer_id
        LEFT JOIN
    geo AS g ON g.zip_code_prefix = c.customer_zip_code_prefix
GROUP BY g.state
ORDER BY avg_duration_hours DESC;

SELECT 
    *
FROM
    orders;

/* How many orders are delivered on time vs orders delivered with a delay? */
SELECT 
    o.order_status,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    TIMESTAMPDIFF(HOUR,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date) AS delay_hours
FROM
    orders AS o
WHERE
    TIMESTAMPDIFF(HOUR,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date) < 0;
        
/* 11% of orders are delayed or not delivered at all! */
SELECT 
    CASE
        WHEN
            SIGN(TIMESTAMPDIFF(HOUR,
                        o.order_delivered_customer_date,
                        o.order_estimated_delivery_date)) = - 1
        THEN
            'delayed'
        WHEN
            SIGN(TIMESTAMPDIFF(HOUR,
                        o.order_delivered_customer_date,
                        o.order_estimated_delivery_date)) = 0
        THEN
            'on time'
        WHEN
            SIGN(TIMESTAMPDIFF(HOUR,
                        o.order_delivered_customer_date,
                        o.order_estimated_delivery_date)) = 1
        THEN
            'early'
        ELSE 'not delivered'
    END AS delay_status,
    COUNT(o.order_status) AS abs_count,
    COUNT(o.order_status) / 99441 * 100 AS perc_count
FROM
    orders AS o
GROUP BY delay_status;


/* Is there any pattern for delayed orders, e.g. big products being delayed more often? */
/* Delayed or undelivered products are bigger and heavier on average, but only a bit, probably insignificant! 
No positive correlation of delay with number of ordered items! */
SELECT 
    CASE
        WHEN
            SIGN(TIMESTAMPDIFF(HOUR,
                        o.order_delivered_customer_date,
                        o.order_estimated_delivery_date)) = - 1
        THEN
            'delayed'
        WHEN
            SIGN(TIMESTAMPDIFF(HOUR,
                        o.order_delivered_customer_date,
                        o.order_estimated_delivery_date)) = 0
        THEN
            'on time'
        WHEN
            SIGN(TIMESTAMPDIFF(HOUR,
                        o.order_delivered_customer_date,
                        o.order_estimated_delivery_date)) = 1
        THEN
            'early'
        ELSE 'not delivered'
    END AS delay_status,
    AVG(i.freight_value) AS avg_freight_value,
    AVG(i.order_item_id) AS avg_order_item_id,
    AVG(p.product_weight_g) AS avg_weight,
    AVG(p.product_length_cm * p.product_height_cm * p.product_width_cm) AS avg_volume_ccm,
    AVG(p.product_length_cm) AS avg_length_cm,
    AVG(p.product_height_cm) AS avg_height_cm,
    AVG(p.product_width_cm) AS avg_width_cm
FROM
    orders AS o
        LEFT JOIN
    order_items AS i ON o.order_id = i.order_id
        LEFT JOIN
    products AS p ON i.product_id = p.product_id
GROUP BY delay_status
ORDER BY delay_status DESC
;

/* Avg delivery diff times vary by up to factor ~2.5 across states! 
Delivery service worst in isolated states with bad logistics (Amazonas, ...)*/
SELECT 
    g.state,
    CASE
        WHEN
            SIGN(TIMESTAMPDIFF(HOUR,
                        o.order_delivered_customer_date,
                        o.order_estimated_delivery_date)) = - 1
        THEN
            'delayed'
        WHEN
            SIGN(TIMESTAMPDIFF(HOUR,
                        o.order_delivered_customer_date,
                        o.order_estimated_delivery_date)) = 0
        THEN
            'on time'
        WHEN
            SIGN(TIMESTAMPDIFF(HOUR,
                        o.order_delivered_customer_date,
                        o.order_estimated_delivery_date)) = 1
        THEN
            'early'
        ELSE 'not delivered'
    END AS delay_status,
    AVG(TIMESTAMPDIFF(HOUR,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date)) AS avg_delivery_diff_hours,
    MAX(TIMESTAMPDIFF(HOUR,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date)) AS max_delivery_diff_hours,
    MIN(TIMESTAMPDIFF(HOUR,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date)) AS min_delivery_diff_hours,
	count(o.order_id) as order_amount
FROM
    orders AS o
        LEFT JOIN
    customers AS c ON o.customer_id = c.customer_id
        LEFT JOIN
    geo AS g ON g.zip_code_prefix = c.customer_zip_code_prefix
GROUP BY g.state , delay_status
ORDER BY avg_delivery_diff_hours DESC;

/* Amount of total deliveries in each state: */
SELECT 
    g.state, COUNT(*) AS amount
FROM
    orders AS o
        LEFT JOIN
    customers AS c ON o.customer_id = c.customer_id
        LEFT JOIN
    geo AS g ON g.zip_code_prefix = c.customer_zip_code_prefix
GROUP BY g.state
ORDER BY amount DESC;
