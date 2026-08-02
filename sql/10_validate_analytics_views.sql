/*
10_validate_analytics_views.sql

Purpose:
Validate the cleaned analytics views before connecting Power BI.

Run note:
Run this while connected to the grocery_retail_bi database.
*/

-- =========================================================
-- 1. Confirm analytics views exist
-- =========================================================

SELECT
    table_schema,
    table_name
FROM information_schema.views
WHERE table_schema = 'analytics'
ORDER BY table_name;


-- =========================================================
-- 2. Confirm key row counts
-- =========================================================

SELECT
    'analytics.vw_fact_sales_clean' AS view_name,
    COUNT(*) AS row_count
FROM analytics.vw_fact_sales_clean

UNION ALL

SELECT
    'analytics.vw_dim_product',
    COUNT(*)
FROM analytics.vw_dim_product

UNION ALL

SELECT
    'analytics.vw_dim_household',
    COUNT(*)
FROM analytics.vw_dim_household

UNION ALL

SELECT
    'analytics.vw_dim_store',
    COUNT(*)
FROM analytics.vw_dim_store

UNION ALL

SELECT
    'analytics.vw_dim_retail_calendar',
    COUNT(*)
FROM analytics.vw_dim_retail_calendar;


-- =========================================================
-- 3. Compare raw fact rows with cleaned fact rows
-- =========================================================

SELECT
    raw_count.raw_transaction_rows,
    clean_count.clean_fact_rows,
    clean_count.clean_fact_rows - raw_count.raw_transaction_rows AS row_difference,
    CASE
        WHEN raw_count.raw_transaction_rows = clean_count.clean_fact_rows THEN 'PASS'
        ELSE 'CHECK'
    END AS validation_status
FROM (
    SELECT COUNT(*) AS raw_transaction_rows
    FROM raw.transaction_data
) raw_count
CROSS JOIN (
    SELECT COUNT(*) AS clean_fact_rows
    FROM analytics.vw_fact_sales_clean
) clean_count;


-- =========================================================
-- 4. Validate margin assumptions
-- =========================================================

SELECT
    COUNT(*) AS margin_assumption_rows,
    MIN(estimated_margin_rate) AS min_margin_rate,
    MAX(estimated_margin_rate) AS max_margin_rate
FROM ref.margin_assumptions;


-- =========================================================
-- 5. Check fact rows without margin rate
-- =========================================================

SELECT
    COUNT(*) AS fact_rows_without_margin_rate
FROM analytics.vw_fact_sales_clean
WHERE estimated_margin_rate IS NULL;


-- =========================================================
-- 6. Executive KPI preview
-- =========================================================

SELECT
    ROUND(SUM(sales_value), 2) AS total_sales,
    SUM(quantity) AS units_sold,
    COUNT(DISTINCT basket_id) AS basket_count,
    ROUND(SUM(sales_value) / NULLIF(COUNT(DISTINCT basket_id), 0), 2) AS average_basket_value,
    ROUND(SUM(total_discount_amount), 2) AS total_discount_amount,
    ROUND(
        SUM(total_discount_amount) / NULLIF(SUM(estimated_gross_shelf_value), 0),
        4
    ) AS discount_pressure_pct,
    ROUND(SUM(estimated_gross_margin), 2) AS estimated_gross_margin
FROM analytics.vw_fact_sales_clean;


-- =========================================================
-- 7. Department performance preview
-- =========================================================

SELECT
    department,
    transaction_rows,
    basket_count,
    total_sales,
    total_discount_amount,
    discount_pressure_pct,
    estimated_gross_margin,
    estimated_margin_pct
FROM analytics.vw_department_performance
ORDER BY total_sales DESC
LIMIT 15;


-- =========================================================
-- 8. Weekly sales preview
-- =========================================================

SELECT
    week_no,
    basket_count,
    total_sales,
    total_discount_amount,
    estimated_gross_margin,
    average_basket_value
FROM analytics.vw_weekly_sales
ORDER BY week_no
LIMIT 15;


-- =========================================================
-- 9. Product performance preview
-- =========================================================

SELECT
    product_id,
    department,
    commodity_desc,
    total_sales,
    total_discount_amount,
    discount_pressure_pct,
    estimated_gross_margin,
    promotion_risk_flag
FROM analytics.vw_product_performance
ORDER BY total_sales DESC
LIMIT 15;


-- =========================================================
-- 10. Customer summary preview
-- =========================================================

SELECT
    household_key,
    age_group,
    homeowner_desc,
    basket_count,
    total_sales,
    average_basket_value,
    customer_value_band,
    demographic_match_status
FROM analytics.vw_customer_summary
ORDER BY total_sales DESC
LIMIT 15;


-- =========================================================
-- 11. Data quality overview preview
-- =========================================================

SELECT
    object_name,
    row_count,
    flagged_rows
FROM analytics.vw_data_quality_overview
ORDER BY object_name;