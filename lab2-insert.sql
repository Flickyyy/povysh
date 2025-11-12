\connect dwh

SET search_path TO dwh, public;

TRUNCATE TABLE receipt, fact_sale, dim_product_category, dim_category, dim_product, dim_customer, dim_branch, dim_date RESTART IDENTITY CASCADE;

-- Small calendar for the sample period
INSERT INTO dwh.dim_date (full_date, year, quarter, month, month_name, day, day_of_week, day_name, is_weekend)
SELECT
   day::DATE,
   EXTRACT(YEAR FROM day)::INT,
   EXTRACT(QUARTER FROM day)::INT,
   EXTRACT(MONTH FROM day)::INT,
   TO_CHAR(day, 'Month'),
   EXTRACT(DAY FROM day)::INT,
   EXTRACT(ISODOW FROM day)::INT,
   TO_CHAR(day, 'Day'),
   CASE WHEN EXTRACT(ISODOW FROM day) IN (6, 7) THEN TRUE ELSE FALSE END
FROM generate_series('2024-01-01'::DATE, '2024-02-29'::DATE, '1 day') AS day;

-- Branches
INSERT INTO dwh.dim_branch (branch_name) VALUES
   ('Филиал Запад'),
   ('Филиал Восток');

-- Customers (IDs are just illustrative)
INSERT INTO dwh.dim_customer (source_customer_id, customer_name) VALUES
   (1001, 'West Customer 01'), (1002, 'West Customer 02'), (1003, 'West Customer 03'),
   (1004, 'West Customer 04'), (1005, 'West Customer 05'),
   (2001, 'East Customer 01'), (2002, 'East Customer 02'), (2003, 'East Customer 03'),
   (2004, 'East Customer 04'), (2005, 'East Customer 05');

-- Products
INSERT INTO dwh.dim_product (source_product_id, product_name) VALUES
   (1001, 'West Product 01'), (1002, 'West Product 02'), (1003, 'West Product 03'),
   (1004, 'West Product 04'), (1005, 'West Product 05'),
   (2001, 'East Product 01'), (2002, 'East Product 02'), (2003, 'East Product 03'),
   (2004, 'East Product 04'), (2005, 'East Product 05');

-- Categories
INSERT INTO dwh.dim_category (category_name) VALUES
   ('West Category Home'), ('West Category Office'), ('West Category Sport'),
   ('West Category Garden'), ('East Category Sport'), ('East Category Kids');

INSERT INTO dwh.dim_product_category (product_key, category_key) VALUES
   ((SELECT product_key FROM dwh.dim_product WHERE product_name = 'West Product 01'),
    (SELECT category_key FROM dwh.dim_category WHERE category_name = 'West Category Home')),
   ((SELECT product_key FROM dwh.dim_product WHERE product_name = 'West Product 02'),
    (SELECT category_key FROM dwh.dim_category WHERE category_name = 'West Category Office')),
   ((SELECT product_key FROM dwh.dim_product WHERE product_name = 'West Product 03'),
    (SELECT category_key FROM dwh.dim_category WHERE category_name = 'West Category Sport')),
   ((SELECT product_key FROM dwh.dim_product WHERE product_name = 'West Product 04'),
    (SELECT category_key FROM dwh.dim_category WHERE category_name = 'West Category Home')),
   ((SELECT product_key FROM dwh.dim_product WHERE product_name = 'West Product 05'),
    (SELECT category_key FROM dwh.dim_category WHERE category_name = 'West Category Garden')),
   ((SELECT product_key FROM dwh.dim_product WHERE product_name = 'East Product 01'),
    (SELECT category_key FROM dwh.dim_category WHERE category_name = 'East Category Sport')),
   ((SELECT product_key FROM dwh.dim_product WHERE product_name = 'East Product 02'),
    (SELECT category_key FROM dwh.dim_category WHERE category_name = 'East Category Kids')),
   ((SELECT product_key FROM dwh.dim_product WHERE product_name = 'East Product 03'),
    (SELECT category_key FROM dwh.dim_category WHERE category_name = 'East Category Sport')),
   ((SELECT product_key FROM dwh.dim_product WHERE product_name = 'East Product 04'),
    (SELECT category_key FROM dwh.dim_category WHERE category_name = 'East Category Kids')),
   ((SELECT product_key FROM dwh.dim_product WHERE product_name = 'East Product 05'),
    (SELECT category_key FROM dwh.dim_category WHERE category_name = 'East Category Sport'));

-- Fact sales (manual sample rows)
WITH
dates AS (
   SELECT full_date, date_key FROM dwh.dim_date WHERE full_date BETWEEN '2024-01-05' AND '2024-02-25'
),
branches AS (
   SELECT branch_name, branch_key FROM dwh.dim_branch
),
customers AS (
   SELECT customer_name, customer_key FROM dwh.dim_customer
),
products AS (
   SELECT product_name, product_key FROM dwh.dim_product
),
source_data AS (
   SELECT * FROM (VALUES
   ('2024-01-05'::DATE, 'Филиал Запад', 'West Customer 01', 'West Product 01', 2, 14.00, 100001, 100001001),
   ('2024-01-08'::DATE, 'Филиал Запад', 'West Customer 02', 'West Product 02', 1, 22.00, 100002, 100002002),
   ('2024-01-10'::DATE, 'Филиал Запад', 'West Customer 03', 'West Product 03', 1, 35.50, 100003, 100003003),
   ('2024-01-15'::DATE, 'Филиал Запад', 'West Customer 05', 'West Product 04', 3, 17.50, 100004, 100004004),
   ('2024-02-05'::DATE, 'Филиал Восток', 'East Customer 01', 'East Product 01', 1, 19.50, 200001, 200001001),
   ('2024-02-07'::DATE, 'Филиал Восток', 'East Customer 02', 'East Product 02', 2, 27.00, 200002, 200002002),
   ('2024-02-12'::DATE, 'Филиал Восток', 'East Customer 04', 'East Product 04', 1, 40.00, 200003, 200003004),
   ('2024-02-18'::DATE, 'Филиал Восток', 'East Customer 05', 'East Product 03', 2, 31.00, 200004, 200004003)
   ) AS v(full_date, branch_name, customer_name, product_name, quantity, unit_price, source_deal_id, source_deal_product_id)
)
INSERT INTO dwh.fact_sale (date_key, branch_key, customer_key, product_key, quantity, unit_price, source_deal_id, source_deal_product_id)
SELECT
   d.date_key,
   b.branch_key,
   c.customer_key,
   p.product_key,
   v.quantity,
   v.unit_price,
   v.source_deal_id,
   v.source_deal_product_id
FROM source_data v
JOIN dates d ON d.full_date = v.full_date
JOIN branches b ON b.branch_name = v.branch_name
JOIN customers c ON c.customer_name = v.customer_name
JOIN products p ON p.product_name = v.product_name;

-- Receipts simply mirror the fact entries (one per sale)
INSERT INTO dwh.receipt (sale_key, receipt_date, payment_method)
SELECT sale_key,
          (SELECT full_date FROM dwh.dim_date WHERE date_key = fs.date_key)::TIMESTAMP,
          'Card'
FROM dwh.fact_sale fs;
