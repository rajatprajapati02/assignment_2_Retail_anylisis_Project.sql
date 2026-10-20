# Retail Sales Analysis with PostgreSQL

NDMIT Data Science | SQL Assignment-2

I wrote 15 SQL queries to answer business questions on a retail dataset: who the best customers are, which categories earn the most, how revenue moves month to month, and how returns and stock look.

## Dataset

Six tables, provided with the assignment:

| Table | What it holds |
|---|---|
| `customers` | name, email, city, state, signup date |
| `products` | category, current price, stock quantity |
| `employees` | department, branch city, monthly salary |
| `orders` | order date, customer, employee, status, payment method |
| `order_items` | quantity, price at time of sale, discount rate |
| `returns` | return date and reason per returned order |

Order status is one of `Delivered`, `Returned` or `Cancelled`.

## How revenue is calculated

```sql
quantity * unit_price_at_sale * (1 - discount_rate)
```

This is worked out per order line first, then summed. Revenue counts only `Delivered` orders unless the question says otherwise. Details are in [ASSUMPTIONS.md](ASSUMPTIONS.md).

## Queries

| # | Topic | Technique |
|---|---|---|
| Q1 | Delivered orders, Oct 2024 to Mar 2025 | `WHERE`, `ORDER BY` |
| Q2 | Orders with customer and employee names | `INNER JOIN` |
| Q3 | Category units and net revenue above 10,000 | `GROUP BY`, `HAVING` |
| Q4 | Customers with 2 or more delivered orders | `COUNT(DISTINCT)`, `HAVING` |
| Q5 | All customers with delivered order count | `LEFT JOIN` |
| Q6 | Products priced above the average | Subquery |
| Q7 | Customers with no delivered order | `NOT EXISTS` |
| Q8 | Monthly orders and net revenue | `EXTRACT` |
| Q9 | Stock label per product | `CASE` |
| Q10 | Delivered, returned, cancelled per employee | Conditional aggregation |
| Q11 | Product rank within category | `RANK() OVER` |
| Q12 | Monthly revenue and running total | `DATE_TRUNC`, `SUM() OVER` |
| Q13 | Returned orders with pre-discount value | Multi-table join |
| Q14 | Customers above average net revenue | CTE |
| Q15 | Top 3 customers and share of total revenue | CTE, window function |

## Repository structure

```
.
├── README.md
├── ASSUMPTIONS.md
├── schema_and_data.sql   -- CREATE TABLE + INSERT (provided with the assignment)
└── queries.sql           -- Q1 to Q15
```

## How to run

1. Install PostgreSQL 12 or later and open pgAdmin or `psql`.
2. Create a database, for example `retail_analysis`, and connect to it.
3. Run `schema_and_data.sql` to create and fill the tables.
4. Run the queries in `queries.sql` one at a time and check the output.

## Notes while building this

- In Q5, Q10 and Q11 the `Delivered` filter has to sit in the join (or a CTE), not in `WHERE`. Otherwise customers, employees or products with no activity vanish from the result.
- In Q4, Q8 and Q15 an order has several items, so orders are counted with `COUNT(DISTINCT order_id)` to avoid counting an order once per item.
- PostgreSQL's `ROUND(x, 2)` needs a `numeric` value, so results are cast with `::numeric` first.

## Author

**Rajat Prajapati**
Learning Data Science at NDMIT. Working on SQL, Python and data analysis projects.
