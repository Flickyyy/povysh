SET search_path TO dwh, public;

CREATE EXTENSION IF NOT EXISTS dblink;
CREATE SCHEMA IF NOT EXISTS etl;

CREATE TABLE IF NOT EXISTS etl.branch_config (
    branch_name TEXT PRIMARY KEY,
    db_name TEXT NOT NULL,
    branch_code INTEGER NOT NULL
);

INSERT INTO etl.branch_config (branch_name, db_name, branch_code)
VALUES
    ('Филиал Запад', 'west_branch', 1),
    ('Филиал Восток', 'east_branch', 2)
ON CONFLICT (branch_name) DO UPDATE
SET db_name = EXCLUDED.db_name,
    branch_code = EXCLUDED.branch_code;

CREATE OR REPLACE PROCEDURE etl.load_from_branches()
LANGUAGE plpgsql
AS $$
DECLARE
    branch_rec RECORD;
    conn TEXT;
BEGIN
    FOR branch_rec IN SELECT * FROM etl.branch_config ORDER BY branch_code LOOP
        BEGIN
            PERFORM dblink_disconnect('branch_conn');
        EXCEPTION WHEN OTHERS THEN
            -- ignore missing connection
            NULL;
        END;

        conn := format('dbname=%I user=postgres password=postgres', branch_rec.db_name);
    PERFORM dwh.dblink_connect('branch_conn'::TEXT, conn::TEXT);

        INSERT INTO dwh.dim_branch (branch_name)
        VALUES (branch_rec.branch_name)
        ON CONFLICT (branch_name) DO NOTHING;

        WITH src AS (
            SELECT branch_rec.branch_code * 1000 + c.customerid AS source_id,
                   c.name,
                   c.rowguid,
                   c.modifieddate
            FROM dwh.dblink(
                'branch_conn',
                'SELECT customerid, name, rowguid, modifieddate FROM customer'
            ) AS c(customerid INT, name TEXT, rowguid UUID, modifieddate TIMESTAMP)
        )
        INSERT INTO dwh.dim_customer (source_customer_id, customer_name, rowguid, modified_date)
        SELECT source_id, name, rowguid, modifieddate
        FROM src
        ON CONFLICT (source_customer_id) DO UPDATE
        SET customer_name = EXCLUDED.customer_name,
            modified_date = EXCLUDED.modified_date;

        WITH src AS (
            SELECT branch_rec.branch_code * 1000 + p.productid AS source_id,
                   p.name,
                   p.rowguid,
                   p.modifieddate
            FROM dwh.dblink(
                'branch_conn',
                'SELECT productid, name, rowguid, modifieddate FROM product'
            ) AS p(productid INT, name TEXT, rowguid UUID, modifieddate TIMESTAMP)
        )
        INSERT INTO dwh.dim_product (source_product_id, product_name, rowguid, modified_date)
        SELECT source_id, name, rowguid, modifieddate
        FROM src
        ON CONFLICT (source_product_id) DO UPDATE
        SET product_name = EXCLUDED.product_name,
            modified_date = EXCLUDED.modified_date;

        WITH src AS (
            SELECT c.name,
                   c.rowguid,
                   c.modifieddate
            FROM dwh.dblink(
                'branch_conn',
                'SELECT name, rowguid, modifieddate FROM category'
            ) AS c(name TEXT, rowguid UUID, modifieddate TIMESTAMP)
        )
        INSERT INTO dwh.dim_category (category_name, rowguid, modified_date)
        SELECT name, rowguid, modifieddate
        FROM src
        ON CONFLICT (category_name) DO UPDATE
        SET modified_date = EXCLUDED.modified_date;

        WITH src AS (
            SELECT branch_rec.branch_code * 1000 + pc.productid AS source_product_id,
                   pc.rowguid,
                   pc.modifieddate,
                   pc.category_name
            FROM dwh.dblink(
                'branch_conn',
                'SELECT pc.productid, pc.rowguid, pc.modifieddate, cat.name AS category_name
                 FROM productcategory pc
                 JOIN category cat ON cat.categoryid = pc.categoryid'
            ) AS pc(productid INT, rowguid UUID, modifieddate TIMESTAMP, category_name TEXT)
        )
        INSERT INTO dwh.dim_product_category (product_key, category_key, rowguid, modified_date)
        SELECT prod.product_key,
               cat.category_key,
               src.rowguid,
               src.modifieddate
        FROM src
        JOIN dwh.dim_product prod ON prod.source_product_id = src.source_product_id
        JOIN dwh.dim_category cat ON cat.category_name = src.category_name
        ON CONFLICT (product_key, category_key) DO UPDATE
        SET modified_date = EXCLUDED.modified_date;

        WITH src AS (
            SELECT branch_rec.branch_code * 100000 + sales.dealid AS source_deal_id,
                   branch_rec.branch_code * 1000000 + sales.dealid * 100 + sales.productid AS source_deal_product_id,
                   branch_rec.branch_code * 1000 + sales.customerid AS source_customer_id,
                   branch_rec.branch_code * 1000 + sales.productid AS source_product_id,
                   sales.dealdate,
                   sales.quantity,
                   sales.price,
                   sales.rowguid,
                   sales.modifieddate
            FROM dwh.dblink(
                'branch_conn',
                'SELECT d.dealid,
                        d.customerid,
                        d.dealdate,
                        dp.productid,
                        dp.quantity,
                        dp.price,
                        dp.rowguid,
                        dp.modifieddate
                 FROM deal d
                 JOIN dealproduct dp ON dp.dealid = d.dealid'
            ) AS sales(
                dealid INT,
                customerid INT,
                dealdate TIMESTAMP,
                productid INT,
                quantity INT,
                price NUMERIC(10, 2),
                rowguid UUID,
                modifieddate TIMESTAMP
            )
        ), inserted AS (
            INSERT INTO dwh.fact_sale (
                date_key,
                branch_key,
                customer_key,
                product_key,
                quantity,
                unit_price,
                source_deal_id,
                source_deal_product_id,
                rowguid,
                modified_date
            )
            SELECT dd.date_key,
                   br.branch_key,
                   cust.customer_key,
                   prod.product_key,
                   src.quantity,
                   src.price,
                   src.source_deal_id,
                   src.source_deal_product_id,
                   src.rowguid,
                   src.modifieddate
            FROM src
            JOIN dwh.dim_date dd ON dd.full_date = src.dealdate::DATE
            JOIN dwh.dim_branch br ON br.branch_name = branch_rec.branch_name
            JOIN dwh.dim_customer cust ON cust.source_customer_id = src.source_customer_id
            JOIN dwh.dim_product prod ON prod.source_product_id = src.source_product_id
            WHERE NOT EXISTS (
                SELECT 1
                FROM dwh.fact_sale existing
                WHERE existing.source_deal_product_id = src.source_deal_product_id
            )
            RETURNING sale_key, source_deal_id
        )
     INSERT INTO dwh.receipt (sale_key, receipt_date, payment_method)
     SELECT ins.sale_key,
         dd.full_date::TIMESTAMP,
         'Card'
     FROM inserted ins
     JOIN dwh.fact_sale fs ON fs.sale_key = ins.sale_key
     JOIN dwh.dim_date dd ON dd.date_key = fs.date_key
     ON CONFLICT (sale_key) DO NOTHING;

    PERFORM dwh.dblink_disconnect('branch_conn'::TEXT);
    END LOOP;

    -- Safety net: ensure every fact row has a receipt in case предыдущий запуск оборвался
    INSERT INTO dwh.receipt (sale_key, receipt_date, payment_method)
    SELECT fs.sale_key,
        dd.full_date::TIMESTAMP,
        'Card'
    FROM dwh.fact_sale fs
    JOIN dwh.dim_date dd ON dd.date_key = fs.date_key
    LEFT JOIN dwh.receipt r ON r.sale_key = fs.sale_key
    WHERE r.sale_key IS NULL
    ON CONFLICT (sale_key) DO NOTHING;
END;
$$;
