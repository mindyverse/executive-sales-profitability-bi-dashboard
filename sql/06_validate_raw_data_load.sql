/*
06_validate_raw_data_load.sql

Purpose:
Validate that the required raw CSV files were loaded into PostgreSQL and
that database row counts match the source profiling baseline.

Run note:
Run this while connected to the grocery_retail_bi database.
*/

-- 1. Compare loaded row counts against the source profiling baseline

WITH expected_counts AS (
    SELECT 'raw.transaction_data' AS table_name, 2595732::bigint AS expected_rows
    UNION ALL
    SELECT 'raw.product', 92353::bigint
    UNION ALL
    SELECT 'raw.hh_demographic', 801::bigint
),
actual_counts AS (
    SELECT 'raw.transaction_data' AS table_name, COUNT(*)::bigint AS actual_rows
    FROM raw.transaction_data

    UNION ALL

    SELECT 'raw.product' AS table_name, COUNT(*)::bigint AS actual_rows
    FROM raw.product

    UNION ALL

    SELECT 'raw.hh_demographic' AS table_name, COUNT(*)::bigint AS actual_rows
    FROM raw.hh_demographic
)
SELECT
    e.table_name,
    e.expected_rows,
    a.actual_rows,
    CASE
        WHEN e.expected_rows = a.actual_rows THEN 'PASS'
        ELSE 'CHECK'
    END AS validation_status
FROM expected_counts e
JOIN actual_counts a
    ON e.table_name = a.table_name
ORDER BY e.table_name;


-- 2. Confirm store lookup was populated from distinct transaction stores

SELECT
    'distinct stores in raw.transaction_data' AS metric,
    COUNT(DISTINCT store_id)::bigint AS value
FROM raw.transaction_data
WHERE store_id IS NOT NULL

UNION ALL

SELECT
    'rows in ref.store_lookup' AS metric,
    COUNT(*)::bigint AS value
FROM ref.store_lookup;


-- 3. Confirm margin assumptions are intentionally still empty

SELECT
    COUNT(*) AS margin_assumption_rows
FROM ref.margin_assumptions;


-- 4. Basic loaded-data preview

SELECT
    household_key,
    basket_id,
    day,
    product_id,
    quantity,
    sales_value,
    store_id,
    retail_disc,
    trans_time,
    week_no,
    coupon_disc,
    coupon_match_disc
FROM raw.transaction_data
LIMIT 10;


-- 5. Product preview

SELECT
    product_id,
    manufacturer,
    department,
    brand,
    commodity_desc,
    sub_commodity_desc,
    curr_size_of_product
FROM raw.product
LIMIT 10;


-- 6. Household demographic preview

SELECT
    classification_1,
    classification_2,
    classification_3,
    homeowner_desc,
    classification_5,
    classification_4,
    kid_category_desc,
    household_key
FROM raw.hh_demographic
LIMIT 10;