# Methodology

## Overview

This project uses a simple SQL-to-Power BI workflow.

The raw CSV files are first loaded into PostgreSQL. I then use SQL views to prepare cleaner, business-ready tables for the dashboard. This keeps the original source data unchanged while making the reporting layer easier to understand and validate.

## Data Layers

| Layer | Purpose |
|---|---|
| Raw tables | Store source-style CSV data in PostgreSQL |
| Reference tables | Store supporting lookup and assumption data |
| Analytics views | Prepare Power BI-ready fact and dimension views |
| Power BI model | Build relationships, DAX measures and dashboard pages |

## Cleaned View Approach

The cleaned SQL views do not manually overwrite the raw data.

Instead, they:

- standardize blank category labels as `UNKNOWN`
- convert discount fields into positive reporting amounts
- calculate discount pressure
- attach estimated department margin rates
- calculate estimated gross margin
- prepare product, household, store and retail calendar dimensions
- keep row-quality flags visible for transparency

## Profitability Method

The source dataset does not contain actual product cost or cost of goods sold.

Because of that, this project does not calculate exact accounting profit. It uses a department-level estimated gross margin assumption table to create a profitability proxy.

This is useful for business analysis, but it should always be read as an estimate.

## Household Demographics

The demographic file does not cover every transaction household.

Instead of removing transactions without demographic matches, the cleaned views keep those sales and label the missing demographic fields as `UNKNOWN`. This avoids losing valid sales records while still being transparent about missing customer information.

## Discount Treatment

The source discount fields may use negative values to represent reductions.

For dashboard reporting, discount amount is calculated using absolute values. This makes the business interpretation clearer because discount value is shown as a positive amount.

## Power BI Preparation

The analytics views are designed to support a star-schema-style model:

- `vw_fact_sales_clean`
- `vw_dim_product`
- `vw_dim_household`
- `vw_dim_store`
- `vw_dim_retail_calendar`

Additional summary views support validation and dashboard development:

- `vw_department_performance`
- `vw_product_performance`
- `vw_weekly_sales`
- `vw_customer_summary`
- `vw_data_quality_overview`