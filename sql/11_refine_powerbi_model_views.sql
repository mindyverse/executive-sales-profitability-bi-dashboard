/*
11_refine_powerbi_model_views.sql

Purpose:
Refine analytics views before Power BI relationship modelling.

Main change:
Dim_Household is rebuilt from all distinct transaction households, then joined
to available demographic records. This keeps households without demographics
in the Power BI dimension and labels missing demographic fields as UNKNOWN.

Run note:
Run this while connected to the grocery_retail_bi database.
*/

DROP VIEW IF EXISTS analytics.vw_data_quality_overview CASCADE;
DROP VIEW IF EXISTS analytics.vw_customer_summary CASCADE;
DROP VIEW IF EXISTS analytics.vw_fact_sales_clean CASCADE;
DROP VIEW IF EXISTS analytics.vw_dim_household CASCADE;


CREATE VIEW analytics.vw_dim_household AS
WITH transaction_households AS (
    SELECT DISTINCT
        household_key
    FROM raw.transaction_data
    WHERE household_key IS NOT NULL
),
household_ranked AS (
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
),
household_clean AS (
    SELECT
        household_key,
        classification_1,
        classification_2,
        classification_3,
        homeowner_desc,
        classification_5,
        classification_4,
        kid_category_desc
    FROM household_ranked
    WHERE row_num = 1
)
SELECT
    th.household_key,

    COALESCE(NULLIF(TRIM(h.classification_1), ''), 'UNKNOWN') AS age_group,
    COALESCE(NULLIF(TRIM(h.classification_2), ''), 'UNKNOWN') AS demographic_classification_2,
    COALESCE(NULLIF(TRIM(h.classification_3), ''), 'UNKNOWN') AS demographic_classification_3,
    COALESCE(NULLIF(TRIM(h.homeowner_desc), ''), 'UNKNOWN') AS homeowner_desc,
    COALESCE(NULLIF(TRIM(h.classification_5), ''), 'UNKNOWN') AS demographic_classification_5,
    COALESCE(NULLIF(TRIM(h.classification_4), ''), 'UNKNOWN') AS demographic_classification_4,
    COALESCE(NULLIF(TRIM(h.kid_category_desc), ''), 'UNKNOWN') AS kid_category_desc,

    CASE
        WHEN h.household_key IS NULL THEN 'No demographic match'
        ELSE 'Has demographic match'
    END AS demographic_match_status

FROM transaction_households th
LEFT JOIN household_clean h
    ON th.household_key = h.household_key;


COMMENT ON VIEW analytics.vw_dim_household IS
'Household dimension built from all transaction households. Missing demographic attributes are labelled UNKNOWN.';


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

    h.age_group,
    h.demographic_classification_2,
    h.demographic_classification_3,
    h.homeowner_desc,
    h.demographic_classification_5,
    h.demographic_classification_4,
    h.kid_category_desc,
    h.demographic_match_status,

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
    END AS customer_value_band

FROM grouped g
LEFT JOIN analytics.vw_dim_household h
    ON g.household_key = h.household_key;


COMMENT ON VIEW analytics.vw_customer_summary IS
'Household-level sales summary with available demographics and UNKNOWN handling.';


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