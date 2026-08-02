/*
07_data_quality_checks.sql

Purpose:
Run data-quality checks after loading the required dunnhumby source files
into PostgreSQL.

Run note:
Run this while connected to the grocery_retail_bi database.

Important:
This script does not clean or delete data. It only profiles and diagnoses
quality risks before analytical views are created.
*/

-- =========================================================
-- 1. Row count reconciliation
-- =========================================================

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

    SELECT 'raw.product', COUNT(*)::bigint
    FROM raw.product

    UNION ALL

    SELECT 'raw.hh_demographic', COUNT(*)::bigint
    FROM raw.hh_demographic
)
SELECT
    e.table_name,
    e.expected_rows,
    a.actual_rows,
    a.actual_rows - e.expected_rows AS row_difference,
    CASE
        WHEN e.expected_rows = a.actual_rows THEN 'PASS'
        ELSE 'CHECK'
    END AS status
FROM expected_counts e
JOIN actual_counts a
    ON e.table_name = a.table_name
ORDER BY e.table_name;


-- =========================================================
-- 2. Transaction key null checks
-- =========================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE household_key IS NULL) AS missing_household_key,
    COUNT(*) FILTER (WHERE basket_id IS NULL) AS missing_basket_id,
    COUNT(*) FILTER (WHERE day IS NULL) AS missing_day,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS missing_product_id,
    COUNT(*) FILTER (WHERE quantity IS NULL) AS missing_quantity,
    COUNT(*) FILTER (WHERE sales_value IS NULL) AS missing_sales_value,
    COUNT(*) FILTER (WHERE store_id IS NULL) AS missing_store_id,
    COUNT(*) FILTER (WHERE week_no IS NULL) AS missing_week_no
FROM raw.transaction_data;


-- =========================================================
-- 3. Product key and hierarchy null checks
-- =========================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS missing_product_id,
    COUNT(*) FILTER (WHERE department IS NULL OR TRIM(department) = '') AS missing_department,
    COUNT(*) FILTER (WHERE brand IS NULL OR TRIM(brand) = '') AS missing_brand,
    COUNT(*) FILTER (WHERE commodity_desc IS NULL OR TRIM(commodity_desc) = '') AS missing_commodity_desc,
    COUNT(*) FILTER (WHERE sub_commodity_desc IS NULL OR TRIM(sub_commodity_desc) = '') AS missing_sub_commodity_desc
FROM raw.product;


-- =========================================================
-- 4. Household demographic null checks
-- =========================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE household_key IS NULL) AS missing_household_key,
    COUNT(*) FILTER (WHERE classification_1 IS NULL OR TRIM(classification_1) = '') AS missing_classification_1,
    COUNT(*) FILTER (WHERE classification_2 IS NULL OR TRIM(classification_2) = '') AS missing_classification_2,
    COUNT(*) FILTER (WHERE classification_3 IS NULL OR TRIM(classification_3) = '') AS missing_classification_3,
    COUNT(*) FILTER (WHERE homeowner_desc IS NULL OR TRIM(homeowner_desc) = '') AS missing_homeowner_desc,
    COUNT(*) FILTER (WHERE kid_category_desc IS NULL OR TRIM(kid_category_desc) = '') AS missing_kid_category_desc
FROM raw.hh_demographic;


-- =========================================================
-- 5. Product identifier uniqueness
-- =========================================================

SELECT
    COUNT(*) AS total_product_rows,
    COUNT(DISTINCT product_id) AS distinct_product_ids,
    COUNT(*) - COUNT(DISTINCT product_id) AS duplicate_product_id_rows
FROM raw.product;


-- Show duplicated product IDs if any exist

SELECT
    product_id,
    COUNT(*) AS row_count
FROM raw.product
GROUP BY product_id
HAVING COUNT(*) > 1
ORDER BY row_count DESC, product_id
LIMIT 50;


-- =========================================================
-- 6. Household identifier uniqueness
-- =========================================================

SELECT
    COUNT(*) AS total_household_rows,
    COUNT(DISTINCT household_key) AS distinct_household_keys,
    COUNT(*) - COUNT(DISTINCT household_key) AS duplicate_household_key_rows
FROM raw.hh_demographic;


-- Show duplicated household keys if any exist

SELECT
    household_key,
    COUNT(*) AS row_count
FROM raw.hh_demographic
GROUP BY household_key
HAVING COUNT(*) > 1
ORDER BY row_count DESC, household_key
LIMIT 50;


-- =========================================================
-- 7. Duplicate full transaction rows
-- =========================================================

WITH grouped_transactions AS (
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
        coupon_match_disc,
        COUNT(*) AS row_count
    FROM raw.transaction_data
    GROUP BY
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
    HAVING COUNT(*) > 1
)
SELECT
    COUNT(*) AS duplicated_row_patterns,
    COALESCE(SUM(row_count - 1), 0) AS extra_duplicate_rows
FROM grouped_transactions;


-- =========================================================
-- 8. Quantity and sales value checks
-- =========================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE quantity < 0) AS negative_quantity_rows,
    COUNT(*) FILTER (WHERE quantity = 0) AS zero_quantity_rows,
    COUNT(*) FILTER (WHERE quantity > 100) AS quantity_over_100_rows,
    COUNT(*) FILTER (WHERE sales_value < 0) AS negative_sales_rows,
    COUNT(*) FILTER (WHERE sales_value = 0) AS zero_sales_rows,
    COUNT(*) FILTER (WHERE sales_value > 500) AS sales_over_500_rows,
    MIN(quantity) AS min_quantity,
    MAX(quantity) AS max_quantity,
    MIN(sales_value) AS min_sales_value,
    MAX(sales_value) AS max_sales_value
FROM raw.transaction_data;


-- Preview unusual quantity or sales rows

SELECT
    household_key,
    basket_id,
    day,
    product_id,
    quantity,
    sales_value,
    store_id,
    retail_disc,
    coupon_disc,
    coupon_match_disc
FROM raw.transaction_data
WHERE quantity <= 0
   OR sales_value <= 0
   OR quantity > 100
   OR sales_value > 500
ORDER BY sales_value DESC, quantity DESC
LIMIT 100;


-- =========================================================
-- 9. Discount sign convention checks
-- =========================================================

SELECT
    COUNT(*) AS total_rows,

    COUNT(*) FILTER (WHERE retail_disc < 0) AS retail_disc_negative_rows,
    COUNT(*) FILTER (WHERE retail_disc = 0) AS retail_disc_zero_rows,
    COUNT(*) FILTER (WHERE retail_disc > 0) AS retail_disc_positive_rows,

    COUNT(*) FILTER (WHERE coupon_disc < 0) AS coupon_disc_negative_rows,
    COUNT(*) FILTER (WHERE coupon_disc = 0) AS coupon_disc_zero_rows,
    COUNT(*) FILTER (WHERE coupon_disc > 0) AS coupon_disc_positive_rows,

    COUNT(*) FILTER (WHERE coupon_match_disc < 0) AS coupon_match_disc_negative_rows,
    COUNT(*) FILTER (WHERE coupon_match_disc = 0) AS coupon_match_disc_zero_rows,
    COUNT(*) FILTER (WHERE coupon_match_disc > 0) AS coupon_match_disc_positive_rows,

    MIN(retail_disc) AS min_retail_disc,
    MAX(retail_disc) AS max_retail_disc,
    MIN(coupon_disc) AS min_coupon_disc,
    MAX(coupon_disc) AS max_coupon_disc,
    MIN(coupon_match_disc) AS min_coupon_match_disc,
    MAX(coupon_match_disc) AS max_coupon_match_disc
FROM raw.transaction_data;


-- =========================================================
-- 10. Gross shelf value sanity check
-- =========================================================
-- Discounts are usually stored as negative reductions in this dataset.
-- For reporting, we will later use ABS(discount fields).
-- This check estimates gross value as sales + absolute discount values.

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (
        WHERE sales_value
            + ABS(retail_disc)
            + ABS(coupon_disc)
            + ABS(coupon_match_disc) < sales_value
    ) AS gross_value_below_sales_rows,
    MIN(
        sales_value
        + ABS(retail_disc)
        + ABS(coupon_disc)
        + ABS(coupon_match_disc)
    ) AS min_estimated_gross_value,
    MAX(
        sales_value
        + ABS(retail_disc)
        + ABS(coupon_disc)
        + ABS(coupon_match_disc)
    ) AS max_estimated_gross_value
FROM raw.transaction_data;


-- =========================================================
-- 11. Product relationship check
-- =========================================================
-- Transactions without a matching product record would weaken category reporting.

SELECT
    COUNT(*) AS transaction_rows_without_product_match
FROM raw.transaction_data t
LEFT JOIN raw.product p
    ON t.product_id = p.product_id
WHERE p.product_id IS NULL;


-- Preview unmatched transaction product IDs if any exist

SELECT
    t.product_id,
    COUNT(*) AS transaction_rows
FROM raw.transaction_data t
LEFT JOIN raw.product p
    ON t.product_id = p.product_id
WHERE p.product_id IS NULL
GROUP BY t.product_id
ORDER BY transaction_rows DESC
LIMIT 50;


-- =========================================================
-- 12. Household demographic relationship check
-- =========================================================
-- Missing demographic matches may be expected because demographic data
-- may not cover every transaction household.

SELECT
    COUNT(DISTINCT t.household_key) AS distinct_transaction_households,
    COUNT(DISTINCT h.household_key) AS households_with_demographic_record,
    COUNT(DISTINCT t.household_key)
        - COUNT(DISTINCT h.household_key) AS transaction_households_without_demographic_record
FROM raw.transaction_data t
LEFT JOIN raw.hh_demographic h
    ON t.household_key = h.household_key;


-- Transaction rows with and without demographic match

SELECT
    CASE
        WHEN h.household_key IS NULL THEN 'No demographic match'
        ELSE 'Has demographic match'
    END AS demographic_match_status,
    COUNT(*) AS transaction_rows
FROM raw.transaction_data t
LEFT JOIN raw.hh_demographic h
    ON t.household_key = h.household_key
GROUP BY
    CASE
        WHEN h.household_key IS NULL THEN 'No demographic match'
        ELSE 'Has demographic match'
    END
ORDER BY demographic_match_status;


-- =========================================================
-- 13. Store lookup validation
-- =========================================================

SELECT
    COUNT(DISTINCT store_id) AS distinct_transaction_stores
FROM raw.transaction_data
WHERE store_id IS NOT NULL;

SELECT
    COUNT(*) AS store_lookup_rows
FROM ref.store_lookup;


-- Stores in transactions missing from store lookup

SELECT
    t.store_id,
    COUNT(*) AS transaction_rows
FROM raw.transaction_data t
LEFT JOIN ref.store_lookup s
    ON t.store_id = s.store_id
WHERE t.store_id IS NOT NULL
  AND s.store_id IS NULL
GROUP BY t.store_id
ORDER BY transaction_rows DESC
LIMIT 50;


-- =========================================================
-- 14. Day and week range checks
-- =========================================================

SELECT
    MIN(day) AS min_day,
    MAX(day) AS max_day,
    COUNT(DISTINCT day) AS distinct_days,
    MIN(week_no) AS min_week_no,
    MAX(week_no) AS max_week_no,
    COUNT(DISTINCT week_no) AS distinct_weeks
FROM raw.transaction_data;


-- Check whether each week roughly maps to a sequence of days

SELECT
    week_no,
    MIN(day) AS min_day,
    MAX(day) AS max_day,
    COUNT(DISTINCT day) AS distinct_days_in_week,
    COUNT(*) AS transaction_rows
FROM raw.transaction_data
GROUP BY week_no
ORDER BY week_no
LIMIT 20;


-- =========================================================
-- 15. Department and category coverage
-- =========================================================

SELECT
    COUNT(DISTINCT department) AS distinct_departments,
    COUNT(DISTINCT commodity_desc) AS distinct_commodities,
    COUNT(DISTINCT sub_commodity_desc) AS distinct_sub_commodities,
    COUNT(DISTINCT brand) AS distinct_brands
FROM raw.product;


-- Department row distribution

SELECT
    department,
    COUNT(*) AS product_rows
FROM raw.product
GROUP BY department
ORDER BY product_rows DESC;


-- =========================================================
-- 16. Department coverage in transactions
-- =========================================================

SELECT
    p.department,
    COUNT(*) AS transaction_rows,
    SUM(t.sales_value) AS total_sales
FROM raw.transaction_data t
JOIN raw.product p
    ON t.product_id = p.product_id
GROUP BY p.department
ORDER BY total_sales DESC;

## Compact SQL Summary Output

```text
"Day and week range"	"Distinct days"	"711"
"Day and week range"	"Distinct weeks"	"102"
"Day and week range"	"Maximum day"	"711"
"Day and week range"	"Maximum week number"	"102"
"Day and week range"	"Minimum day"	"1"
"Day and week range"	"Minimum week number"	"1"
"Department coverage"	"Distinct brands"	"2"
"Department coverage"	"Distinct commodities"	"308"
"Department coverage"	"Distinct departments"	"44"
"Department coverage"	"Distinct sub-commodities"	"2383"
"Discount sign convention"	"Coupon discount negative rows"	"36422"
"Discount sign convention"	"Coupon discount positive rows"	"0"
"Discount sign convention"	"Coupon discount zero rows"	"2559310"
"Discount sign convention"	"Coupon match discount negative rows"	"17449"
"Discount sign convention"	"Coupon match discount positive rows"	"0"
"Discount sign convention"	"Coupon match discount zero rows"	"2578283"
"Discount sign convention"	"Retail discount negative rows"	"1303018"
"Discount sign convention"	"Retail discount positive rows"	"10"
"Discount sign convention"	"Retail discount zero rows"	"1292704"
"Household demographic coverage"	"Distinct transaction households"	"2500"
"Household demographic coverage"	"Households with demographic record"	"801"
"Household demographic coverage"	"Transaction households without demographic record"	"1699"
"Household key check"	"Distinct household keys"	"801"
"Household key check"	"Duplicate household key rows"	"0"
"Household key check"	"Household rows"	"801"
"Missing transaction keys"	"Missing basket_id"	"0"
"Missing transaction keys"	"Missing household_key"	"0"
"Missing transaction keys"	"Missing product_id"	"0"
"Missing transaction keys"	"Missing quantity"	"0"
"Missing transaction keys"	"Missing sales_value"	"0"
"Missing transaction keys"	"Missing store_id"	"0"
"Missing transaction keys"	"Missing week_no"	"0"
"Product key check"	"Distinct product IDs"	"92353"
"Product key check"	"Duplicate product ID rows"	"0"
"Product key check"	"Product rows"	"92353"
"Quantity and sales"	"Maximum quantity"	"89638"
"Quantity and sales"	"Maximum sales value"	"840.00"
"Quantity and sales"	"Minimum quantity"	"0"
"Quantity and sales"	"Minimum sales value"	"0.00"
"Quantity and sales"	"Negative quantity rows"	"0"
"Quantity and sales"	"Negative sales rows"	"0"
"Quantity and sales"	"Quantity over 100 rows"	"23136"
"Quantity and sales"	"Sales over 500 rows"	"3"
"Quantity and sales"	"Zero quantity rows"	"14466"
"Quantity and sales"	"Zero sales rows"	"18879"
"Relationship check"	"Transaction rows without product match"	"0"
"Row count"	"raw.hh_demographic actual rows"	"801"
"Row count"	"raw.product actual rows"	"92353"
"Row count"	"raw.transaction_data actual rows"	"2595732"
"Store lookup"	"Distinct transaction stores"	"582"
"Store lookup"	"Store lookup rows"	"582"

</>markdown
