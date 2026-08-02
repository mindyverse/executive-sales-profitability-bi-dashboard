/*
05_load_raw_data_template.sql

Purpose:
Template for loading the required dunnhumby CSV files into PostgreSQL.

Important:
This file is safe for GitHub because it does not contain personal local paths.

How to use:
Create a local copy named sql/local_load_raw_data.sql and replace each
placeholder path with the absolute path to the CSV file on your own computer.

Run note:
Run this through psql while connected to the grocery_retail_bi database.
The psql \copy command reads files from the local computer.
*/

\copy raw.product (
    product_id,
    manufacturer,
    department,
    brand,
    commodity_desc,
    sub_commodity_desc,
    curr_size_of_product
)
FROM '<ABSOLUTE_PATH_TO_PRODUCT_CSV>'
WITH (
    FORMAT csv,
    HEADER true,
    DELIMITER ',',
    ENCODING 'UTF8'
);

\copy raw.hh_demographic (
    classification_1,
    classification_2,
    classification_3,
    homeowner_desc,
    classification_5,
    classification_4,
    kid_category_desc,
    household_key
)
FROM '<ABSOLUTE_PATH_TO_HH_DEMOGRAPHIC_CSV>'
WITH (
    FORMAT csv,
    HEADER true,
    DELIMITER ',',
    ENCODING 'UTF8'
);

\copy raw.transaction_data (
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
)
FROM '<ABSOLUTE_PATH_TO_TRANSACTION_DATA_CSV>'
WITH (
    FORMAT csv,
    HEADER true,
    DELIMITER ',',
    ENCODING 'UTF8'
);

INSERT INTO ref.store_lookup (
    store_id,
    store_label,
    source_note
)
SELECT
    store_id,
    'Store ' || store_id AS store_label,
    'Created from distinct store_id values in raw.transaction_data' AS source_note
FROM (
    SELECT DISTINCT store_id
    FROM raw.transaction_data
    WHERE store_id IS NOT NULL
) AS stores
ON CONFLICT (store_id) DO NOTHING;