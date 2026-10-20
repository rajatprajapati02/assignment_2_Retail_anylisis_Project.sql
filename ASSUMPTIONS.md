# Assumptions

Choices I made where the assignment brief or the data left something open. They apply to `queries.sql` (Q1 to Q15), written for PostgreSQL.

## Revenue

1. Net value of a line is `quantity * unit_price_at_sale * (1 - discount_rate)`. It is calculated per order line and then summed to order, customer, product, category or month level.
2. `discount_rate` is a fraction (0.10 means 10% off) and applies to that line only.
3. Revenue uses `unit_price_at_sale`, the price actually charged. `products.unit_price` is the current catalogue price and is used only in Q6.
4. Pre-discount value (Q13) is `quantity * unit_price_at_sale`.
5. Amounts are in Indian Rupees. Tax, shipping and payment fees are not in the data and are ignored.
6. Payment method does not change revenue.
7. Rounding to 2 decimals happens only in the final output, so totals are not distorted by intermediate rounding.

## Order status and returns

1. Only `order_status = 'Delivered'` counts as a completed sale. `Returned` and `Cancelled` orders are excluded from every revenue, spend and ranking figure, as the brief says.
2. Status values are matched exactly as `'Delivered'`, `'Returned'`, `'Cancelled'` (case-sensitive).
3. A returned order is treated as returned in full, because the `returns` table works at order level.
4. Returned orders are left out of revenue entirely instead of being counted and then subtracted.
5. Cancelled orders never shipped, so they produce no revenue and no return.
6. Q13 lists orders found in the `returns` table, not orders chosen by status.

## Dates

1. Revenue belongs to the month of `order_date`, since there is no delivery or payment date.
2. Date ranges include both ends. Q1 filters with `>= '2024-10-01' AND < '2025-04-01'`, which covers all of 31 March 2025 and stays correct even if a time part is ever added.
3. Q8 and Q12 group by year and month together, so the same month in different years is never merged.
4. Q12's running total runs across all months in date order and does not reset at a year boundary.

## Customers, employees and products

1. Each order is credited to the employee on the order, whatever their department.
2. Customers and products are grouped by ID, so two with the same name are never merged.
3. `stock_quantity` is a snapshot and is not reduced by orders in this dataset.
4. Fields such as email, signup date, monthly salary and branch city are descriptive only and are not used in calculations.

## Query-specific choices

| Query | Assumption |
|---|---|
| Q1 | Only delivered orders are listed. |
| Q2 | `INNER JOIN` keeps only orders that have both a matching customer and employee. |
| Q3 | The 10,000 threshold is on net revenue after discount, applied with `HAVING`. |
| Q4 | "At least two orders" means delivered orders only. |
| Q5 | The delivered condition is in the `ON` clause so customers with zero delivered orders still appear with 0. |
| Q6 | The average is a simple mean over all products in the catalogue, including products that never sold. |
| Q7 | A customer with only returned or cancelled orders, or no orders, counts as never having a delivered order. An empty result is valid. |
| Q8 | Orders are counted with `COUNT(DISTINCT order_id)` because joining to `order_items` gives one row per item. |
| Q9 | Stock of exactly 20 or 40 is Moderate Stock. Only above 40 is High Stock. |
| Q10 | Conditional aggregation with `SUM(CASE ...)`. `LEFT JOIN` keeps employees with no orders, shown as 0. |
| Q11 | `RANK()` is used, so ties share a rank and the next rank is skipped. Products with no delivered sales show 0 revenue and are still ranked. |
| Q13 | The value is the full pre-discount value of all items in the returned order. |
| Q14 | **The average is calculated only across customers who have at least one delivered purchase**, not across every customer. Customers with no delivered orders are not in the CTE. |
| Q15 | The percentage share is against total delivered net revenue of all customers, not just the top three. `LIMIT 3` assumes no tie for third place. |

## Technical

1. Written for PostgreSQL 12 or later (`EXTRACT`, `DATE_TRUNC`, `TO_CHAR`, `::numeric` casts).
2. `CREATE DATABASE` is run on its own first, then the session connects to that database before the tables are created.
3. Scripts run in this order: schema, then data, then queries. Foreign keys need `customers`, `products` and `employees` loaded before `orders`.
4. Columns used in calculations (`quantity`, `unit_price_at_sale`, `discount_rate`, `order_status`, `order_date`) are assumed to have no NULLs.
5. The data is a static sample, so results are reproducible.
