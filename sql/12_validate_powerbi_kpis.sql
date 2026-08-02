/*
12_validate_powerbi_kpis.sql

Purpose:
Create a SQL baseline for validating the Power BI DAX measures.

Run note:
Run this while connected to the grocery_retail_bi database.
*/

SELECT
    ROUND(SUM(sales_value), 2) AS total_sales,
    SUM(quantity) AS units_sold,
    COUNT(DISTINCT basket_id) AS basket_count,
    COUNT(*) AS transaction_rows,

    ROUND(
        SUM(sales_value) / NULLIF(COUNT(DISTINCT basket_id), 0),
        2
    ) AS average_basket_value,

    ROUND(SUM(total_discount_amount), 2) AS total_discount_amount,
    ROUND(SUM(estimated_gross_shelf_value), 2) AS estimated_gross_shelf_value,

    ROUND(
        SUM(total_discount_amount) / NULLIF(SUM(estimated_gross_shelf_value), 0),
        4
    ) AS discount_pressure_pct,

    ROUND(SUM(estimated_gross_margin), 2) AS estimated_gross_margin,

    ROUND(
        SUM(estimated_gross_margin) / NULLIF(SUM(sales_value), 0),
        4
    ) AS estimated_margin_pct,

    COUNT(DISTINCT household_key) AS household_count,
    COUNT(DISTINCT store_id) AS store_count,
    COUNT(DISTINCT product_id) AS product_count,

    ROUND(
        SUM(sales_value) / NULLIF(SUM(quantity), 0),
        2
    ) AS average_selling_price,

    ROUND(
        SUM(quantity)::numeric / NULLIF(COUNT(DISTINCT basket_id), 0),
        2
    ) AS average_units_per_basket,

    ROUND(
        SUM(sales_value) / NULLIF(COUNT(DISTINCT household_key), 0),
        2
    ) AS sales_per_household,

    COUNT(*) FILTER (
        WHERE total_discount_amount > 0
    ) AS discounted_transaction_rows,

    ROUND(
        COUNT(*) FILTER (WHERE total_discount_amount > 0)::numeric
        / NULLIF(COUNT(*), 0),
        4
    ) AS discounted_transaction_row_pct,

    COUNT(*) FILTER (
        WHERE row_quality_flag <> 'OK'
    ) AS flagged_transaction_rows,

    ROUND(
        COUNT(*) FILTER (WHERE row_quality_flag <> 'OK')::numeric
        / NULLIF(COUNT(*), 0),
        4
    ) AS flagged_transaction_row_pct

FROM analytics.vw_fact_sales_clean;