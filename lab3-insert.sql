\connect dwh

SET search_path TO dwh, public;

DELETE FROM dm.fact_weekly_sales;
DELETE FROM dm.dim_week;

INSERT INTO dm.dim_week (week_start_date, week_end_date, week_number, year)
SELECT DISTINCT
  DATE_TRUNC('week', dd.full_date)::DATE AS week_start,
  DATE_TRUNC('week', dd.full_date)::DATE + INTERVAL '6 days' AS week_end,
  EXTRACT(WEEK FROM dd.full_date)::INT,
  EXTRACT(YEAR FROM dd.full_date)::INT
FROM dwh.dim_date dd
WHERE dd.full_date BETWEEN '2024-01-01' AND '2024-12-31';

WITH weekly AS (
  SELECT
    DATE_TRUNC('week', dd.full_date)::DATE AS week_start,
    fs.branch_key,
    fs.product_key,
    SUM(fs.quantity) AS total_quantity_sold,
    SUM(fs.quantity * fs.unit_price) AS total_sales_amount,
    COUNT(fs.sale_key) AS number_of_transactions
  FROM dwh.fact_sale fs
  JOIN dwh.dim_date dd ON dd.date_key = fs.date_key
  GROUP BY 1, 2, 3
),
receipt_counts AS (
  SELECT
    DATE_TRUNC('week', r.receipt_date)::DATE AS week_start,
    fs.branch_key,
    fs.product_key,
    COUNT(r.receipt_key) AS receipt_count
  FROM dwh.receipt r
  JOIN dwh.fact_sale fs ON fs.sale_key = r.sale_key
  GROUP BY 1, 2, 3
)
INSERT INTO dm.fact_weekly_sales (
  week_key,
  branch_key,
  product_key,
  total_quantity_sold,
  total_sales_amount,
  number_of_transactions,
  receipt_count,
  load_date
)
SELECT
  dw.week_key,
  w.branch_key,
  w.product_key,
  w.total_quantity_sold,
  w.total_sales_amount,
  w.number_of_transactions,
  COALESCE(rc.receipt_count, 0) AS receipt_count,
  CURRENT_TIMESTAMP
FROM weekly w
JOIN dm.dim_week dw ON dw.week_start_date = w.week_start
LEFT JOIN receipt_counts rc ON rc.week_start = w.week_start AND rc.branch_key = w.branch_key AND rc.product_key = w.product_key;
