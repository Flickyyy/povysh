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
   (1, 'West Customer 01'), (2, 'West Customer 02'), (3, 'West Customer 03'),
   (4, 'West Customer 04'), (5, 'West Customer 05'),
   (101, 'East Customer 01'), (102, 'East Customer 02'), (103, 'East Customer 03'),
   (104, 'East Customer 04'), (105, 'East Customer 05');

-- Products
INSERT INTO dwh.dim_product (source_product_id, product_name) VALUES
   (10, 'West Product 01'), (11, 'West Product 02'), (12, 'West Product 03'),
   (13, 'West Product 04'), (14, 'West Product 05'),
   (210, 'East Product 01'), (211, 'East Product 02'), (212, 'East Product 03'),
   (213, 'East Product 04'), (214, 'East Product 05');

-- Categories
INSERT INTO dwh.dim_category (category_name) VALUES
   ('Home'), ('Office'), ('Sport'), ('Kids'), ('Garden');

INSERT INTO dwh.dim_product_category (product_key, category_key) VALUES
   ((SELECT product_key FROM dwh.dim_product WHERE product_name = 'West Product 01'),
    (SELECT category_key FROM dwh.dim_category WHERE category_name = 'Home')),
   ((SELECT product_key FROM dwh.dim_product WHERE product_name = 'West Product 02'),
    (SELECT category_key FROM dwh.dim_category WHERE category_name = 'Office')),
   ((SELECT product_key FROM dwh.dim_product WHERE product_name = 'West Product 03'),
    (SELECT category_key FROM dwh.dim_category WHERE category_name = 'Sport')),
   ((SELECT product_key FROM dwh.dim_product WHERE product_name = 'West Product 04'),
    (SELECT category_key FROM dwh.dim_category WHERE category_name = 'Home')),
   ((SELECT product_key FROM dwh.dim_product WHERE product_name = 'West Product 05'),
    (SELECT category_key FROM dwh.dim_category WHERE category_name = 'Garden')),
   ((SELECT product_key FROM dwh.dim_product WHERE product_name = 'East Product 01'),
    (SELECT category_key FROM dwh.dim_category WHERE category_name = 'Sport')),
   ((SELECT product_key FROM dwh.dim_product WHERE product_name = 'East Product 02'),
    (SELECT category_key FROM dwh.dim_category WHERE category_name = 'Kids')),
   ((SELECT product_key FROM dwh.dim_product WHERE product_name = 'East Product 03'),
    (SELECT category_key FROM dwh.dim_category WHERE category_name = 'Sport')),
   ((SELECT product_key FROM dwh.dim_product WHERE product_name = 'East Product 04'),
    (SELECT category_key FROM dwh.dim_category WHERE category_name = 'Kids')),
   ((SELECT product_key FROM dwh.dim_product WHERE product_name = 'East Product 05'),
    (SELECT category_key FROM dwh.dim_category WHERE category_name = 'Garden'));

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
      ('2024-01-05'::DATE, 'Филиал Запад', 'West Customer 01', 'West Product 01', 2, 14.00, 1, 1),
      ('2024-01-08'::DATE, 'Филиал Запад', 'West Customer 02', 'West Product 02', 1, 22.00, 2, 2),
      ('2024-01-10'::DATE, 'Филиал Запад', 'West Customer 03', 'West Product 03', 1, 35.50, 3, 3),
      ('2024-01-15'::DATE, 'Филиал Запад', 'West Customer 05', 'West Product 04', 3, 17.50, 4, 4),
      ('2024-02-05'::DATE, 'Филиал Восток', 'East Customer 01', 'East Product 01', 1, 19.50, 101, 1),
      ('2024-02-07'::DATE, 'Филиал Восток', 'East Customer 02', 'East Product 02', 2, 27.00, 102, 2),
      ('2024-02-12'::DATE, 'Филиал Восток', 'East Customer 04', 'East Product 04', 1, 40.00, 104, 4),
      ('2024-02-18'::DATE, 'Филиал Восток', 'East Customer 05', 'East Product 03', 2, 31.00, 105, 3)
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
