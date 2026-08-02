/*
04_validate_empty_tables.sql

Purpose:
Validate that the required empty tables exist before loading CSV data.

Run note:
Run this script while connected to the grocery_retail_bi database.
*/

-- 1. Confirm required tables exist

SELECT
    table_schema,
    table_name
FROM information_schema.tables
WHERE table_schema IN ('raw', 'ref')
  AND table_type = 'BASE TABLE'
ORDER BY
    table_schema,
    table_name;


-- 2. Confirm column counts for the required tables

SELECT
    table_schema,
    table_name,
    COUNT(*) AS column_count
FROM information_schema.columns
WHERE table_schema IN ('raw', 'ref')
  AND table_name IN (
      'transaction_data',
      'product',
      'hh_demographic',
      'store_lookup',
      'margin_assumptions'
  )
GROUP BY
    table_schema,
    table_name
ORDER BY
    table_schema,
    table_name;


-- 3. Show column names and data types

SELECT
    table_schema,
    table_name,
    ordinal_position,
    column_name,
    data_type,
    numeric_precision,
    numeric_scale,
    is_nullable
FROM information_schema.columns
WHERE table_schema IN ('raw', 'ref')
  AND table_name IN (
      'transaction_data',
      'product',
      'hh_demographic',
      'store_lookup',
      'margin_assumptions'
  )
ORDER BY
    table_schema,
    table_name,
    ordinal_position;


-- 4. Confirm all required tables are still empty before data loading

SELECT 'raw.transaction_data' AS table_name, COUNT(*) AS row_count
FROM raw.transaction_data

UNION ALL

SELECT 'raw.product' AS table_name, COUNT(*) AS row_count
FROM raw.product

UNION ALL

SELECT 'raw.hh_demographic' AS table_name, COUNT(*) AS row_count
FROM raw.hh_demographic

UNION ALL

SELECT 'ref.store_lookup' AS table_name, COUNT(*) AS row_count
FROM ref.store_lookup

UNION ALL

SELECT 'ref.margin_assumptions' AS table_name, COUNT(*) AS row_count
FROM ref.margin_assumptions

ORDER BY table_name;