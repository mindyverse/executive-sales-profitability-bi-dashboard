/*
09_create_analytics_views.sql

Purpose:
Create cleaned, Power BI-ready analytics views for the Grocery Retail
Executive Sales and Profitability BI Dashboard project.

Run note:
Run this while connected to the grocery_retail_bi database.
*/

-- Recreate analytics views safely
DROP VIEW IF EXISTS analytics.vw_data_quality_overview CASCADE;
DROP VIEW IF EXISTS analytics.vw_customer_summary CASCADE;
DROP VIEW IF EXISTS analytics.vw_weekly_sales CASCADE;
DROP VIEW IF EXISTS analytics.vw_product_performance CASCADE;
DROP VIEW IF EXISTS analytics.vw_department_performance CASCADE;
DROP VIEW IF EXISTS analytics.vw_fact_sales_clean CASCADE;
DROP VIEW IF EXISTS analytics.vw_dim_retail_calendar CASCADE;
DROP VIEW IF EXISTS analytics.vw_dim_store CASCADE;
DROP VIEW IF EXISTS analytics.vw_dim_household CASCADE;
DROP VIEW IF EXISTS analytics.vw_dim_product CASCADE;


-- =========================================================
-- 1. Product dimension
-- =========================================================

CREATE VIEW analytics.vw_dim_product AS
WITH product_ranked AS (
    SELECT
        product_id,
        manufacturer,
        department,
        brand,
        commodity_desc,
        sub_commodity_desc,
        curr_size_of_product,
        ROW_NUMBER() OVER (
            PARTITION BY product_id
            ORDER BY product_id
        ) AS row_num
    FROM raw.product
    WHERE product_id IS NOT NULL
)
SELECT
    product_id,
    manufacturer,

    COALESCE(NULLIF(TRIM(department), ''), 'UNKNOWN') AS department,

    COALESCE(NULLIF(TRIM(brand), ''), 'UNKNOWN') AS brand,

    COALESCE(NULLIF(TRIM(commodity_desc), ''), 'UNKNOWN') AS commodity_desc,

    COALESCE(NULLIF(TRIM(sub_commodity_desc), ''), 'UNKNOWN') AS sub_commodity_desc,

    COALESCE(NULLIF(TRIM(curr_size_of_product), ''), 'UNKNOWN') AS product_size

FROM product_ranked
WHERE row_num = 1;


COMMENT ON VIEW analytics.vw_dim_product IS
'Cleaned product dimension for Power BI. One row per product_id.';


-- =========================================================
-- 2. Household dimension
-- =========================================================

CREATE VIEW analytics.vw_dim_household AS
WITH household_ranked AS (
    SELECT
        household_key,
        classification_1,
        classification_2,
        classification_3,
        homeowner_desc,
        classification_5,
        classification_4,
        kid_category_desc,
        ROW_NUMBER() OVER (
            PARTITION BY household_key
            ORDER BY household_key
        ) AS row_num
    FROM raw.hh_demographic
    WHERE household_key IS NOT NULL
)
SELECT
    household_key,

    COALESCE(NULLIF(TRIM(classification_1), ''), 'UNKNOWN') AS age_group,

    COALESCE(NULLIF(TRIM(classification_2), ''), 'UNKNOWN') AS demographic_classification_2,

    COALESCE(NULLIF(TRIM(classification_3), ''), 'UNKNOWN') AS demographic_classification_3,

    COALESCE(NULLIF(TRIM(homeowner_desc), ''), 'UNKNOWN') AS homeowner_desc,

    COALESCE(NULLIF(TRIM(classification_5), ''), 'UNKNOWN') AS demographic_classification_5,

    COALESCE(NULLIF(TRIM(classification_4), ''), 'UNKNOWN') AS demographic_classification_4,

    COALESCE(NULLIF(TRIM(kid_category_desc), ''), 'UNKNOWN') AS kid_category_desc

FROM household_ranked
WHERE row_num = 1;


COMMENT ON VIEW analytics.vw_dim_household IS
'Cleaned household demographic dimension. Missing transaction households will be handled as Unknown in summary views.';


-- =========================================================
-- 3. Store dimension
-- =========================================================

CREATE VIEW analytics.vw_dim_store AS
SELECT
    store_id,
    COALESCE(NULLIF(TRIM(store_label), ''), 'Store ' || store_id) AS store_label,
    COALESCE(NULLIF(TRIM(source_note), ''), 'Created from transaction store IDs') AS source_note
FROM ref.store_lookup
WHERE store_id IS NOT NULL;


COMMENT ON VIEW analytics.vw_dim_store IS
'Store dimension generated from distinct transaction store IDs.';


-- =========================================================
-- 4. Retail calendar dimension
-- =========================================================

CREATE VIEW analytics.vw_dim_retail_calendar AS
SELECT DISTINCT
    day,
    week_no,

    'Day ' || day AS day_label,

    'Week ' || week_no AS week_label,

    ((day - 1) % 7) + 1 AS retail_day_of_week,

    CASE
        WHEN week_no <= 52 THEN 1
        WHEN week_no <= 104 THEN 2
        ELSE CEILING(week_no / 52.0)::integer
    END AS retail_year,

    ((week_no - 1) % 52) + 1 AS retail_week_in_year

FROM raw.transaction_data
WHERE day IS NOT NULL
  AND week_no IS NOT NULL;


COMMENT ON VIEW analytics.vw_dim_retail_calendar IS
'Simple retail day and week dimension created from transaction day and week fields. It does not claim actual calendar dates.';


-- =========================================================
-- 5. Clean sales fact view
-- =========================================================

CREATE VIEW analytics.vw_fact_sales_clean AS
WITH base AS (
    SELECT
        t.household_key,
        t.basket_id,
        t.day,
        t.week_no,
        t.product_id,
        t.store_id,
        t.trans_time,

        t.quantity,
        t.sales_value,
        t.retail_disc,
        t.coupon_disc,
        t.coupon_match_disc,

        ABS(COALESCE(t.retail_disc, 0)) AS retail_discount_amount,
        ABS(COALESCE(t.coupon_disc, 0)) AS coupon_discount_amount,
        ABS(COALESCE(t.coupon_match_disc, 0)) AS coupon_match_discount_amount,

        ABS(COALESCE(t.retail_disc, 0))
        + ABS(COALESCE(t.coupon_disc, 0))
        + ABS(COALESCE(t.coupon_match_disc, 0)) AS total_discount_amount,

        COALESCE(t.sales_value, 0)
        + ABS(COALESCE(t.retail_disc, 0))
        + ABS(COALESCE(t.coupon_disc, 0))
        + ABS(COALESCE(t.coupon_match_disc, 0)) AS estimated_gross_shelf_value,

        CASE
            WHEN t.household_key IS NULL
              OR t.basket_id IS NULL
              OR t.product_id IS NULL
              OR t.store_id IS NULL
              OR t.day IS NULL
              OR t.week_no IS NULL
                THEN 'Missing key field'

            WHEN t.quantity < 0 THEN 'Negative quantity'
            WHEN t.sales_value < 0 THEN 'Negative sales value'
            WHEN t.quantity = 0 THEN 'Zero quantity'
            WHEN t.sales_value = 0 THEN 'Zero sales value'
            ELSE 'OK'
        END AS row_quality_flag

    FROM raw.transaction_data t
)
SELECT
    b.household_key,
    b.basket_id,
    b.day,
    b.week_no,
    b.product_id,
    b.store_id,
    b.trans_time,

    b.quantity,
    b.sales_value,
    b.retail_disc,
    b.coupon_disc,
    b.coupon_match_disc,

    b.retail_discount_amount,
    b.coupon_discount_amount,
    b.coupon_match_discount_amount,
    b.total_discount_amount,
    b.estimated_gross_shelf_value,

    CASE
        WHEN b.estimated_gross_shelf_value = 0 THEN 0
        ELSE ROUND(
            b.total_discount_amount / NULLIF(b.estimated_gross_shelf_value, 0),
            4
        )
    END AS discount_pressure_pct,

    p.department,
    COALESCE(m.estimated_margin_rate, 0.2500) AS estimated_margin_rate,

    ROUND(
        COALESCE(b.sales_value, 0) * COALESCE(m.estimated_margin_rate, 0.2500),
        2
    ) AS estimated_gross_margin,

    b.row_quality_flag

FROM base b
LEFT JOIN analytics.vw_dim_product p
    ON b.product_id = p.product_id
LEFT JOIN ref.margin_assumptions m
    ON p.department = m.department;


COMMENT ON VIEW analytics.vw_fact_sales_clean IS
'Cleaned Power BI fact view. Includes positive discount amounts, discount pressure and estimated gross margin proxy.';


-- =========================================================
-- 6. Department performance view
-- =========================================================

CREATE VIEW analytics.vw_department_performance AS
SELECT
    COALESCE(department, 'UNKNOWN') AS department,

    COUNT(*) AS transaction_rows,
    COUNT(DISTINCT basket_id) AS basket_count,
    COUNT(DISTINCT household_key) AS household_count,

    SUM(COALESCE(quantity, 0)) AS units_sold,
    ROUND(SUM(COALESCE(sales_value, 0)), 2) AS total_sales,
    ROUND(SUM(total_discount_amount), 2) AS total_discount_amount,
    ROUND(SUM(estimated_gross_shelf_value), 2) AS estimated_gross_shelf_value,
    ROUND(SUM(estimated_gross_margin), 2) AS estimated_gross_margin,

    ROUND(
        SUM(total_discount_amount) / NULLIF(SUM(estimated_gross_shelf_value), 0),
        4
    ) AS discount_pressure_pct,

    ROUND(
        SUM(estimated_gross_margin) / NULLIF(SUM(COALESCE(sales_value, 0)), 0),
        4
    ) AS estimated_margin_pct

FROM analytics.vw_fact_sales_clean
GROUP BY COALESCE(department, 'UNKNOWN');


COMMENT ON VIEW analytics.vw_department_performance IS
'Department-level sales, discount and estimated margin summary.';


-- =========================================================
-- 7. Product performance view
-- =========================================================

CREATE VIEW analytics.vw_product_performance AS
WITH grouped AS (
    SELECT
        f.product_id,
        p.department,
        p.brand,
        p.commodity_desc,
        p.sub_commodity_desc,
        p.product_size,

        COUNT(*) AS transaction_rows,
        COUNT(DISTINCT f.basket_id) AS basket_count,
        SUM(COALESCE(f.quantity, 0)) AS units_sold,
        SUM(COALESCE(f.sales_value, 0)) AS total_sales,
        SUM(f.total_discount_amount) AS total_discount_amount,
        SUM(f.estimated_gross_shelf_value) AS estimated_gross_shelf_value,
        SUM(f.estimated_gross_margin) AS estimated_gross_margin

    FROM analytics.vw_fact_sales_clean f
    LEFT JOIN analytics.vw_dim_product p
        ON f.product_id = p.product_id
    GROUP BY
        f.product_id,
        p.department,
        p.brand,
        p.commodity_desc,
        p.sub_commodity_desc,
        p.product_size
)
SELECT
    product_id,
    department,
    brand,
    commodity_desc,
    sub_commodity_desc,
    product_size,

    transaction_rows,
    basket_count,
    units_sold,
    ROUND(total_sales, 2) AS total_sales,
    ROUND(total_discount_amount, 2) AS total_discount_amount,
    ROUND(estimated_gross_shelf_value, 2) AS estimated_gross_shelf_value,
    ROUND(estimated_gross_margin, 2) AS estimated_gross_margin,

    ROUND(
        total_discount_amount / NULLIF(estimated_gross_shelf_value, 0),
        4
    ) AS discount_pressure_pct,

    CASE
        WHEN total_sales >= 10000
         AND total_discount_amount / NULLIF(estimated_gross_shelf_value, 0) >= 0.25
            THEN 'Review discount pressure'
        ELSE 'Normal'
    END AS promotion_risk_flag

FROM grouped;


COMMENT ON VIEW analytics.vw_product_performance IS
'Product-level sales, discount, estimated margin and promotion-risk view.';


-- =========================================================
-- 8. Weekly sales view
-- =========================================================

CREATE VIEW analytics.vw_weekly_sales AS
SELECT
    week_no,

    COUNT(*) AS transaction_rows,
    COUNT(DISTINCT basket_id) AS basket_count,
    COUNT(DISTINCT household_key) AS household_count,

    SUM(COALESCE(quantity, 0)) AS units_sold,
    ROUND(SUM(COALESCE(sales_value, 0)), 2) AS total_sales,
    ROUND(SUM(total_discount_amount), 2) AS total_discount_amount,
    ROUND(SUM(estimated_gross_margin), 2) AS estimated_gross_margin,

    ROUND(
        SUM(COALESCE(sales_value, 0))
        / NULLIF(COUNT(DISTINCT basket_id), 0),
        2
    ) AS average_basket_value

FROM analytics.vw_fact_sales_clean
GROUP BY week_no;


COMMENT ON VIEW analytics.vw_weekly_sales IS
'Weekly sales and basket trend view for Power BI.';


-- =========================================================
-- 9. Customer summary view
-- =========================================================

CREATE VIEW analytics.vw_customer_summary AS
WITH grouped AS (
    SELECT
        f.household_key,
        COUNT(DISTINCT f.basket_id) AS basket_count,
        COUNT(*) AS transaction_rows,
        SUM(COALESCE(f.quantity, 0)) AS units_sold,
        SUM(COALESCE(f.sales_value, 0)) AS total_sales,
        SUM(f.total_discount_amount) AS total_discount_amount,
        SUM(f.estimated_gross_margin) AS estimated_gross_margin
    FROM analytics.vw_fact_sales_clean f
    WHERE f.household_key IS NOT NULL
    GROUP BY f.household_key
)
SELECT
    g.household_key,

    COALESCE(h.age_group, 'UNKNOWN') AS age_group,
    COALESCE(h.demographic_classification_2, 'UNKNOWN') AS demographic_classification_2,
    COALESCE(h.demographic_classification_3, 'UNKNOWN') AS demographic_classification_3,
    COALESCE(h.homeowner_desc, 'UNKNOWN') AS homeowner_desc,
    COALESCE(h.demographic_classification_5, 'UNKNOWN') AS demographic_classification_5,
    COALESCE(h.demographic_classification_4, 'UNKNOWN') AS demographic_classification_4,
    COALESCE(h.kid_category_desc, 'UNKNOWN') AS kid_category_desc,

    g.basket_count,
    g.transaction_rows,
    g.units_sold,
    ROUND(g.total_sales, 2) AS total_sales,
    ROUND(g.total_discount_amount, 2) AS total_discount_amount,
    ROUND(g.estimated_gross_margin, 2) AS estimated_gross_margin,

    ROUND(
        g.total_sales / NULLIF(g.basket_count, 0),
        2
    ) AS average_basket_value,

    CASE
        WHEN g.total_sales >= 5000 THEN 'High value'
        WHEN g.total_sales >= 1000 THEN 'Medium value'
        ELSE 'Low value'
    END AS customer_value_band,

    CASE
        WHEN h.household_key IS NULL THEN 'No demographic match'
        ELSE 'Has demographic match'
    END AS demographic_match_status

FROM grouped g
LEFT JOIN analytics.vw_dim_household h
    ON g.household_key = h.household_key;


COMMENT ON VIEW analytics.vw_customer_summary IS
'Household-level sales summary with available demographics and Unknown handling.';


-- =========================================================
-- 10. Data quality overview view
-- =========================================================

CREATE VIEW analytics.vw_data_quality_overview AS
SELECT
    'raw.transaction_data' AS object_name,
    COUNT(*)::bigint AS row_count,
    COUNT(*) FILTER (WHERE row_quality_flag <> 'OK')::bigint AS flagged_rows
FROM analytics.vw_fact_sales_clean

UNION ALL

SELECT
    'analytics.vw_dim_product' AS object_name,
    COUNT(*)::bigint AS row_count,
    0::bigint AS flagged_rows
FROM analytics.vw_dim_product

UNION ALL

SELECT
    'analytics.vw_dim_household' AS object_name,
    COUNT(*)::bigint AS row_count,
    0::bigint AS flagged_rows
FROM analytics.vw_dim_household

UNION ALL

SELECT
    'analytics.vw_dim_store' AS object_name,
    COUNT(*)::bigint AS row_count,
    0::bigint AS flagged_rows
FROM analytics.vw_dim_store

UNION ALL

SELECT
    'analytics.vw_dim_retail_calendar' AS object_name,
    COUNT(*)::bigint AS row_count,
    0::bigint AS flagged_rows
FROM analytics.vw_dim_retail_calendar;


COMMENT ON VIEW analytics.vw_data_quality_overview IS
'Small overview used for the dashboard methodology and data-quality page.';