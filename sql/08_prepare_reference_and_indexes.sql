/*
08_prepare_reference_and_indexes.sql

Purpose:
Prepare reference data and indexes before creating the analytics views.

Run note:
Run this while connected to the grocery_retail_bi database.

Important:
The margin rates below are assumptions, not actual profit rates. The dataset
does not include product cost, so estimated gross margin must be presented
as a proxy.
*/

-- =========================================================
-- 1. Add useful indexes for joins and grouped analysis
-- =========================================================

CREATE INDEX IF NOT EXISTS idx_transaction_product_id
ON raw.transaction_data (product_id);

CREATE INDEX IF NOT EXISTS idx_transaction_household_key
ON raw.transaction_data (household_key);

CREATE INDEX IF NOT EXISTS idx_transaction_store_id
ON raw.transaction_data (store_id);

CREATE INDEX IF NOT EXISTS idx_transaction_day
ON raw.transaction_data (day);

CREATE INDEX IF NOT EXISTS idx_transaction_week_no
ON raw.transaction_data (week_no);

CREATE INDEX IF NOT EXISTS idx_transaction_basket_id
ON raw.transaction_data (basket_id);

CREATE INDEX IF NOT EXISTS idx_product_product_id
ON raw.product (product_id);

CREATE INDEX IF NOT EXISTS idx_product_department
ON raw.product (department);

CREATE INDEX IF NOT EXISTS idx_household_household_key
ON raw.hh_demographic (household_key);


-- =========================================================
-- 2. Populate margin assumptions from distinct departments
-- =========================================================

TRUNCATE TABLE ref.margin_assumptions;

INSERT INTO ref.margin_assumptions (
    department,
    estimated_margin_rate,
    assumption_basis,
    confidence_level
)
SELECT
    department_clean AS department,

    CASE
        WHEN department_clean ILIKE '%KIOSK%'
          OR department_clean ILIKE '%GAS%'
            THEN 0.0800

        WHEN department_clean ILIKE '%MEAT%'
            THEN 0.2200

        WHEN department_clean ILIKE '%GROCERY%'
            THEN 0.2500

        WHEN department_clean ILIKE '%SEAFOOD%'
            THEN 0.2500

        WHEN department_clean ILIKE '%PRODUCE%'
            THEN 0.3500

        WHEN department_clean ILIKE '%DELI%'
            THEN 0.3500

        WHEN department_clean ILIKE '%PASTRY%'
            THEN 0.4000

        WHEN department_clean ILIKE '%FLORAL%'
            THEN 0.4500

        WHEN department_clean ILIKE '%COSMETIC%'
            THEN 0.4000

        WHEN department_clean ILIKE '%DRUG%'
            THEN 0.3200

        WHEN department_clean = 'UNKNOWN'
            THEN 0.2500

        ELSE 0.2500
    END AS estimated_margin_rate,

    CASE
        WHEN department_clean ILIKE '%KIOSK%'
          OR department_clean ILIKE '%GAS%'
            THEN 'Assumed low margin for fuel or kiosk-style sales.'

        WHEN department_clean ILIKE '%MEAT%'
            THEN 'Assumed moderate margin for meat-related retail categories.'

        WHEN department_clean ILIKE '%GROCERY%'
            THEN 'Assumed standard grocery margin proxy.'

        WHEN department_clean ILIKE '%PRODUCE%'
            THEN 'Assumed higher fresh-category margin proxy.'

        WHEN department_clean ILIKE '%DELI%'
          OR department_clean ILIKE '%PASTRY%'
            THEN 'Assumed higher prepared-food margin proxy.'

        WHEN department_clean ILIKE '%FLORAL%'
            THEN 'Assumed higher specialty-category margin proxy.'

        WHEN department_clean ILIKE '%COSMETIC%'
          OR department_clean ILIKE '%DRUG%'
            THEN 'Assumed general merchandise margin proxy.'

        ELSE 'Default department margin assumption used where no specific rate was assigned.'
    END AS assumption_basis,

    CASE
        WHEN department_clean = 'UNKNOWN' THEN 'Low'
        WHEN department_clean ILIKE '%KIOSK%'
          OR department_clean ILIKE '%GAS%' THEN 'Low'
        ELSE 'Medium'
    END AS confidence_level

FROM (
    SELECT DISTINCT
        COALESCE(NULLIF(TRIM(department), ''), 'UNKNOWN') AS department_clean
    FROM raw.product
) d
ORDER BY department_clean;


-- =========================================================
-- 3. Validate assumption rows
-- =========================================================

SELECT
    COUNT(*) AS margin_assumption_departments,
    MIN(estimated_margin_rate) AS min_margin_rate,
    MAX(estimated_margin_rate) AS max_margin_rate
FROM ref.margin_assumptions;

SELECT
    department,
    estimated_margin_rate,
    confidence_level,
    assumption_basis
FROM ref.margin_assumptions
ORDER BY department;