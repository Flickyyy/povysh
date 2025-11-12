CREATE SCHEMA IF NOT EXISTS dwh;
SET search_path TO dwh, public;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Calendar dimension
CREATE TABLE dwh.dim_date (
	date_key UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	full_date DATE NOT NULL UNIQUE,
	year INTEGER NOT NULL,
	quarter INTEGER NOT NULL,
	month INTEGER NOT NULL,
	month_name VARCHAR(20) NOT NULL,
	day INTEGER NOT NULL,
	day_of_week INTEGER NOT NULL,
	day_name VARCHAR(20) NOT NULL,
	is_weekend BOOLEAN NOT NULL,
	rowguid UUID DEFAULT gen_random_uuid(),
	modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Branch dimension
CREATE TABLE dwh.dim_branch (
	branch_key UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	branch_name VARCHAR(50) NOT NULL UNIQUE,
	rowguid UUID DEFAULT gen_random_uuid(),
	modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Customer dimension
CREATE TABLE dwh.dim_customer (
	customer_key UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	source_customer_id INTEGER NOT NULL,
	customer_name VARCHAR(255) NOT NULL UNIQUE,
	rowguid UUID DEFAULT gen_random_uuid(),
	modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Product dimension
CREATE TABLE dwh.dim_product (
	product_key UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	source_product_id INTEGER NOT NULL,
	product_name VARCHAR(255) NOT NULL,
	rowguid UUID DEFAULT gen_random_uuid(),
	modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Category dimension
CREATE TABLE dwh.dim_category (
	category_key UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	category_name VARCHAR(255) NOT NULL UNIQUE,
	rowguid UUID DEFAULT gen_random_uuid(),
	modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bridge between product and category
CREATE TABLE dwh.dim_product_category (
	product_key UUID NOT NULL REFERENCES dwh.dim_product(product_key),
	category_key UUID NOT NULL REFERENCES dwh.dim_category(category_key),
	rowguid UUID DEFAULT gen_random_uuid(),
	modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	PRIMARY KEY (product_key, category_key)
);

-- Fact table for sales
CREATE TABLE dwh.fact_sale (
	sale_key UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	date_key UUID NOT NULL REFERENCES dwh.dim_date(date_key),
	branch_key UUID NOT NULL REFERENCES dwh.dim_branch(branch_key),
	customer_key UUID NOT NULL REFERENCES dwh.dim_customer(customer_key),
	product_key UUID NOT NULL REFERENCES dwh.dim_product(product_key),
	quantity INTEGER NOT NULL,
	unit_price NUMERIC(10, 2) NOT NULL,
	source_deal_id INTEGER NOT NULL,
	source_deal_product_id INTEGER NOT NULL,
	rowguid UUID DEFAULT gen_random_uuid(),
	modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Receipt dimension
CREATE TABLE dwh.receipt (
	receipt_key UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	sale_key UUID NOT NULL REFERENCES dwh.fact_sale(sale_key),
	receipt_date TIMESTAMP NOT NULL,
	payment_method VARCHAR(50) NOT NULL,
	rowguid UUID DEFAULT gen_random_uuid(),
	modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_receipt_sale ON dwh.receipt(sale_key);

-- Ensure natural keys stay unique for idempotent loads
CREATE UNIQUE INDEX IF NOT EXISTS ux_dim_customer_source ON dwh.dim_customer(source_customer_id);
CREATE UNIQUE INDEX IF NOT EXISTS ux_dim_product_source ON dwh.dim_product(source_product_id);
CREATE UNIQUE INDEX IF NOT EXISTS ux_fact_sale_source ON dwh.fact_sale(source_deal_product_id);
CREATE INDEX IF NOT EXISTS ix_fact_sale_deal ON dwh.fact_sale(source_deal_id);

