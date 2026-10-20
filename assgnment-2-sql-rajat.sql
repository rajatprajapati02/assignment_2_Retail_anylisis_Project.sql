CREATE DATABASE retail_analysis


CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL,
    city VARCHAR(60),
    state VARCHAR(60),
    signup_date DATE);

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(120) NOT NULL,
    category VARCHAR(60),
    unit_price NUMERIC(10,2),
    stock_quantity INT);

CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    employee_name VARCHAR(100) NOT NULL,
    department VARCHAR(60),
    branch_city VARCHAR(60),
    monthly_salary NUMERIC(10,2));

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
    order_date DATE,
    employee_id INT REFERENCES employees(employee_id),
    order_status VARCHAR(30),
    payment_method VARCHAR(30));

CREATE TABLE order_items (
    order_item_id INT PRIMARY KEY,
    order_id INT REFERENCES orders(order_id),
    product_id INT REFERENCES products(product_id),
    quantity INT,
    unit_price_at_sale NUMERIC(10,2),
    discount_rate NUMERIC(4,2));

CREATE TABLE returns (
    return_id INT PRIMARY KEY,
    order_id INT REFERENCES orders(order_id),
    return_date DATE,
    return_reason VARCHAR(120));


SELECT *
	FROM customers;

SELECT *
	FROM employees;

SELECT *
	FROM products;

SELECT *
	FROM order_items;

SELECT *
	FROM orders;

SELECT *
	FROM returns;

--Q1. List delivered orders placed between 1 October 2024 and 31 March 2025. Show order_id, order_date, customer_id, and payment_method. Sort by order date descending.

SELECT
    order_id,
    order_date,
    customer_id,
    payment_method
FROM orders
WHERE order_status = 'Delivered'
  AND order_date >= '2024-10-01'
  AND order_date < '2025-04-01'
ORDER BY order_date DESC;


--Q2. Display each delivered order with customer and employee details.

SELECT
    c.customer_name,
    o.order_id,
    o.order_date,
    e.employee_name,
    o.order_status
FROM orders o
INNER JOIN customers c
    ON o.customer_id = c.customer_id
INNER JOIN employees e
    ON o.employee_id = e.employee_id
WHERE o.order_status = 'Delivered'
ORDER BY o.order_date;

--Q3. Calculate total units sold and net revenue for each product category.


SELECT
    p.category,
    SUM(oi.quantity) AS total_units_sold,
    ROUND(
        SUM(
            oi.quantity * oi.unit_price_at_sale
            * (1 - oi.discount_rate))::numeric,
        2) AS net_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
WHERE o.order_status = 'Delivered'
GROUP BY p.category
HAVING SUM(
    oi.quantity * oi.unit_price_at_sale
    * (1 - oi.discount_rate)) > 10000
ORDER BY net_revenue DESC;


--Q4. Find customers who have placed at least two delivered orders. Show their customer ID, name, number of delivered orders, and total net spend.

SELECT
    c.customer_id,
    c.customer_name,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    ROUND(
        SUM(
            oi.quantity * oi.unit_price_at_sale
            * (1 - oi.discount_rate)
        )::numeric,
        2
    ) AS total_net_spend
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'Delivered'
GROUP BY
    c.customer_id,
    c.customer_name
HAVING COUNT(DISTINCT o.order_id) >= 2
ORDER BY total_net_spend DESC;

--Q5. Find all customers and their delivered order counts.

SELECT
    c.customer_id,
    c.customer_name,
    COUNT(o.order_id) AS total_orders
FROM customers c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id
    AND o.order_status = 'Delivered'
GROUP BY c.customer_id, c.customer_name
ORDER BY total_orders DESC;


--Q6. Find products priced above the average price

SELECT
    product_name,
    category,
    unit_price,
    (SELECT AVG(unit_price) FROM products) AS average_price
FROM products
WHERE unit_price > (SELECT AVG(unit_price) FROM products);


--Q7. Find customers who have never placed a delivered order

SELECT
    customer_id,
    customer_name,
    city
FROM customers c
WHERE NOT EXISTS 
	(SELECT 1
    FROM orders o
    WHERE o.customer_id = c.customer_id
      AND o.order_status = 'Delivered');


--Q8. Find the number of delivered orders and net revenue for each month.
SELECT
    EXTRACT(YEAR FROM o.order_date) AS year,
    EXTRACT(MONTH FROM o.order_date) AS month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.quantity * oi.unit_price_at_sale * (1 - oi.discount_rate))::numeric, 2) AS net_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'Delivered'
GROUP BY
    EXTRACT(YEAR FROM o.order_date),
    EXTRACT(MONTH FROM o.order_date)
ORDER BY year, month;


--Q9. Classify products based on stock quantity
SELECT
    product_name,
    stock_quantity,
    CASE
        WHEN stock_quantity < 20 THEN 'Low Stock'
        WHEN stock_quantity <= 40 THEN 'Moderate Stock'
        ELSE 'High Stock'
    END AS stock_status
FROM products;

--Q10. Count delivered, returned, and cancelled orders for each employee
SELECT
    e.employee_id,
    e.employee_name,
    COUNT(CASE WHEN o.order_status = 'Delivered' THEN 1 END) AS delivered_orders,
    COUNT(CASE WHEN o.order_status = 'Returned' THEN 1 END) AS returned_orders,
    COUNT(CASE WHEN o.order_status = 'Cancelled' THEN 1 END) AS cancelled_orders
FROM employees e
LEFT JOIN orders o
    ON e.employee_id = o.employee_id
GROUP BY e.employee_id, e.employee_name
ORDER BY e.employee_id;


--Q11. Rank products in each category by net revenue
SELECT
    p.category,
    p.product_name,
    COALESCE(SUM(oi.quantity * oi.unit_price_at_sale * (1 - oi.discount_rate)), 0) AS net_revenue,
    RANK() OVER (
        PARTITION BY p.category
        ORDER BY COALESCE(SUM(oi.quantity * oi.unit_price_at_sale * (1 - oi.discount_rate)), 0) DESC
    ) AS product_rank
FROM products p
LEFT JOIN order_items oi
    ON p.product_id = oi.product_id
LEFT JOIN orders o
    ON oi.order_id = o.order_id
    AND o.order_status = 'Delivered'
WHERE oi.order_id IS NULL OR o.order_id IS NOT NULL
GROUP BY p.category, p.product_id, p.product_name
ORDER BY p.category, product_rank;

--Q12. Calculate monthly revenue and running total
SELECT
    DATE_TRUNC('month', o.order_date)::date AS month,
    ROUND(SUM(oi.quantity * oi.unit_price_at_sale * (1 - oi.discount_rate))::numeric, 2) AS monthly_revenue,
    ROUND(
        SUM(SUM(oi.quantity * oi.unit_price_at_sale * (1 - oi.discount_rate))) OVER (
            ORDER BY DATE_TRUNC('month', o.order_date)
        )::numeric,
        2
    ) AS running_total
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'Delivered'
GROUP BY DATE_TRUNC('month', o.order_date)
ORDER BY month;


--Q13. Find returned orders and their total order value
SELECT
    c.customer_name,
    r.return_date,
    r.return_reason,
    SUM(oi.quantity * oi.unit_price_at_sale) AS total_order_value
FROM returns r
JOIN orders o
    ON r.order_id = o.order_id
JOIN customers c
    ON o.customer_id = c.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY
    c.customer_name,
    r.return_date,
    r.return_reason,
    o.order_id
ORDER BY r.return_date;


--Q14. Find customers whose net revenue is above the average
WITH customer_revenue AS (
    SELECT
        c.customer_id,
        c.customer_name,
        SUM(oi.quantity * oi.unit_price_at_sale * (1 - oi.discount_rate)) AS net_revenue
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY c.customer_id, c.customer_name
)
SELECT
    customer_id,
    customer_name,
    ROUND(net_revenue::numeric, 2) AS net_revenue
FROM customer_revenue
WHERE net_revenue > (
    SELECT AVG(net_revenue)
    FROM customer_revenue
)
ORDER BY net_revenue DESC;

--Q15. Find the top three customers by delivered net spend
WITH customer_sales AS (
    SELECT
        c.customer_id,
        c.customer_name,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(oi.quantity * oi.unit_price_at_sale * (1 - oi.discount_rate)) AS net_spend
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY c.customer_id, c.customer_name
)
SELECT
    customer_name,
    total_orders,
    ROUND(net_spend::numeric, 2) AS net_spend,
    ROUND(
        (net_spend * 100.0 / SUM(net_spend) OVER ())::numeric,
        2
    ) AS revenue_percentage
FROM customer_sales
ORDER BY net_spend DESC
LIMIT 3;