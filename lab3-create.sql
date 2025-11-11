SET search_path TO dwh, public;

CREATE SCHEMA IF NOT EXISTS dm;

-- Week dimension inside the warehouse database
CREATE TABLE IF NOT EXISTS dm.dim_week (
  week_key UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  week_start_date DATE NOT NULL,
  week_end_date DATE NOT NULL,
  week_number INTEGER NOT NULL,
  year INTEGER NOT NULL,
  UNIQUE (week_start_date, week_end_date)
);

-- Weekly fact table
CREATE TABLE IF NOT EXISTS dm.fact_weekly_sales (
  weekly_sale_key UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  week_key UUID NOT NULL REFERENCES dm.dim_week(week_key),
  branch_key UUID NOT NULL REFERENCES dwh.dim_branch(branch_key),
  product_key UUID NOT NULL REFERENCES dwh.dim_product(product_key),
  total_quantity_sold INTEGER NOT NULL,
  total_sales_amount NUMERIC(15, 2) NOT NULL,
  number_of_transactions INTEGER NOT NULL,
  receipt_count INTEGER NOT NULL,
  load_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (week_key, branch_key, product_key)
);
