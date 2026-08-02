/*
03_create_tables.sql

Purpose:
Create the required empty PostgreSQL tables for the Grocery Retail Executive
Sales and Profitability BI Dashboard project.

Run note:
Run this script while connected to the grocery_retail_bi database.

Design note:
The raw tables are intentionally close to the source files, but column names
are standardized to lowercase for easier SQL querying.
*/

-- =========================================================
-- Raw transaction table
-- Source file: transaction_data.csv
-- =========================================================

CREATE TABLE IF NOT EXISTS raw.transaction_data (
    household_key       integer,
    basket_id           bigint,
    day                 integer,
    product_id          integer,
    quantity            integer,
    sales_value         numeric(12, 2),
    store_id            integer,
    retail_disc         numeric(12, 2),
    trans_time          integer,
    week_no             integer,
    coupon_disc         numeric(12, 2),
    coupon_match_disc   numeric(12, 2)
);

COMMENT ON TABLE raw.transaction_data IS
'Source-style transaction table loaded from transaction_data.csv. One row represents a product-level transaction line within a basket.';

COMMENT ON COLUMN raw.transaction_data.household_key IS 'Household identifier from the source transaction file.';
COMMENT ON COLUMN raw.transaction_data.basket_id IS 'Shopping basket identifier.';
COMMENT ON COLUMN raw.transaction_data.day IS 'Retail day sequence from the source data.';
COMMENT ON COLUMN raw.transaction_data.product_id IS 'Product identifier used to join to raw.product.';
COMMENT ON COLUMN raw.transaction_data.quantity IS 'Number of product units purchased.';
COMMENT ON COLUMN raw.transaction_data.sales_value IS 'Recorded sales value for the transaction line.';
COMMENT ON COLUMN raw.transaction_data.store_id IS 'Store identifier from the transaction file.';
COMMENT ON COLUMN raw.transaction_data.retail_disc IS 'Retail discount amount from the source file.';
COMMENT ON COLUMN raw.transaction_data.trans_time IS 'Transaction time field from the source file.';
COMMENT ON COLUMN raw.transaction_data.week_no IS 'Retail week number from the source file.';
COMMENT ON COLUMN raw.transaction_data.coupon_disc IS 'Coupon discount amount from the source file.';
COMMENT ON COLUMN raw.transaction_data.coupon_match_disc IS 'Coupon match discount amount from the source file.';


-- =========================================================
-- Raw product table
-- Source file: product.csv
-- =========================================================

CREATE TABLE IF NOT EXISTS raw.product (
    product_id              integer,
    manufacturer            integer,
    department              text,
    brand                   text,
    commodity_desc          text,
    sub_commodity_desc      text,
    curr_size_of_product    text
);

COMMENT ON TABLE raw.product IS
'Source-style product table loaded from product.csv. Contains product hierarchy and descriptive attributes.';

COMMENT ON COLUMN raw.product.product_id IS 'Product identifier used to join product details to transactions.';
COMMENT ON COLUMN raw.product.manufacturer IS 'Manufacturer identifier from the source file.';
COMMENT ON COLUMN raw.product.department IS 'High-level retail department.';
COMMENT ON COLUMN raw.product.brand IS 'Brand classification from the source file.';
COMMENT ON COLUMN raw.product.commodity_desc IS 'Commodity or category description.';
COMMENT ON COLUMN raw.product.sub_commodity_desc IS 'More detailed sub-commodity description.';
COMMENT ON COLUMN raw.product.curr_size_of_product IS 'Source product-size description.';


-- =========================================================
-- Raw household demographic table
-- Source file: hh_demographic.csv
-- =========================================================

CREATE TABLE IF NOT EXISTS raw.hh_demographic (
    classification_1     text,
    classification_2     text,
    classification_3     text,
    homeowner_desc       text,
    classification_5     text,
    classification_4     text,
    kid_category_desc    text,
    household_key        integer
);

COMMENT ON TABLE raw.hh_demographic IS
'Source-style household demographic table loaded from hh_demographic.csv. Some transaction households may not have demographic records.';

COMMENT ON COLUMN raw.hh_demographic.classification_1 IS 'Source demographic classification field 1.';
COMMENT ON COLUMN raw.hh_demographic.classification_2 IS 'Source demographic classification field 2.';
COMMENT ON COLUMN raw.hh_demographic.classification_3 IS 'Source demographic classification field 3.';
COMMENT ON COLUMN raw.hh_demographic.homeowner_desc IS 'Homeownership description.';
COMMENT ON COLUMN raw.hh_demographic.classification_5 IS 'Source demographic classification field 5.';
COMMENT ON COLUMN raw.hh_demographic.classification_4 IS 'Source demographic classification field 4.';
COMMENT ON COLUMN raw.hh_demographic.kid_category_desc IS 'Children-related household category description.';
COMMENT ON COLUMN raw.hh_demographic.household_key IS 'Household identifier used to connect demographics to transactions.';


-- =========================================================
-- Store lookup table
-- Created from distinct store IDs later
-- =========================================================

CREATE TABLE IF NOT EXISTS ref.store_lookup (
    store_id        integer PRIMARY KEY,
    store_label     text,
    source_note     text,
    created_at      timestamp DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE ref.store_lookup IS
'Store lookup table created from distinct store IDs in the transaction data because no separate store metadata file is used in version 1.';

COMMENT ON COLUMN ref.store_lookup.store_id IS 'Store identifier from transaction data.';
COMMENT ON COLUMN ref.store_lookup.store_label IS 'Readable store label created during the project.';
COMMENT ON COLUMN ref.store_lookup.source_note IS 'Short note explaining how the store record was created.';
COMMENT ON COLUMN ref.store_lookup.created_at IS 'Timestamp when the lookup record was created.';


-- =========================================================
-- Margin assumption table
-- Created by analyst after department profiling
-- =========================================================

CREATE TABLE IF NOT EXISTS ref.margin_assumptions (
    department                  text PRIMARY KEY,
    estimated_margin_rate       numeric(5, 4) NOT NULL,
    assumption_basis            text NOT NULL,
    confidence_level            text,
    created_at                  timestamp DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_estimated_margin_rate
        CHECK (estimated_margin_rate >= 0 AND estimated_margin_rate <= 1)
);

COMMENT ON TABLE ref.margin_assumptions IS
'Department-level estimated gross margin assumptions. Used only as a profitability proxy because actual product costs are not available in the source dataset.';

COMMENT ON COLUMN ref.margin_assumptions.department IS 'Department name matched to the product department.';
COMMENT ON COLUMN ref.margin_assumptions.estimated_margin_rate IS 'Estimated gross margin rate between 0 and 1.';
COMMENT ON COLUMN ref.margin_assumptions.assumption_basis IS 'Short explanation of why the assumption was chosen.';
COMMENT ON COLUMN ref.margin_assumptions.confidence_level IS 'Analyst confidence note such as Low, Medium or High.';
COMMENT ON COLUMN ref.margin_assumptions.created_at IS 'Timestamp when the assumption record was created.';