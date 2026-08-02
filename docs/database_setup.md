# Database Setup

## Database Name

`grocery_retail_bi`

## Purpose

This PostgreSQL database stores the local working version of the grocery retail dataset used in this project.

The dataset is large enough that I did not want to depend on spreadsheet-only analysis. PostgreSQL gives the project a more reliable place to load the raw files, check data quality, write reusable SQL, and prepare clean views for Power BI.

## Database Structure

The database uses three main schemas:

| Schema | Purpose |
|---|---|
| `raw` | Source-style tables loaded from the CSV files |
| `ref` | Reference and assumption tables created during the project |
| `analytics` | Cleaned views and reporting-ready objects for Power BI |

## Current Setup Status

The database has been created locally in PostgreSQL.

The following schemas have also been created:

- `raw`
- `ref`
- `analytics`

No raw dataset files are stored in GitHub. The database is rebuilt locally using the SQL scripts and the separately downloaded source files.

## Notes

- Passwords are not stored in this repository.
- Raw CSV files are excluded from Git.
- The database will be used for table loading, data-quality checks, cleaning views, KPI validation, and Power BI connection.
## Tables Created

The first set of project tables has been created.

| Table | Schema | Purpose |
|---|---|---|
| `transaction_data` | `raw` | Source-style transaction lines from the main sales file |
| `product` | `raw` | Product hierarchy and descriptive attributes |
| `hh_demographic` | `raw` | Available household demographic attributes |
| `store_lookup` | `ref` | Store lookup created from transaction store IDs |
| `margin_assumptions` | `ref` | Department-level estimated margin assumptions |

At this stage, the tables are intentionally empty. Data loading will be completed after validating the table structure.
## Raw Data Load

The required source CSV files have been loaded into the `raw` schema.

| Table | Source File | Loaded Rows |
|---|---|---:|
| `raw.transaction_data` | `transaction_data.csv` | 2,595,732 |
| `raw.product` | `product.csv` | 92,353 |
| `raw.hh_demographic` | `hh_demographic.csv` | 801 |

The `ref.store_lookup` table was populated from distinct store IDs in the transaction data.

The `ref.margin_assumptions` table remains empty until department-level profiling is complete.

## Analytics Views

Cleaned SQL views have been created in the `analytics` schema.

| View | Purpose |
|---|---|
| `vw_fact_sales_clean` | Main cleaned sales fact view |
| `vw_dim_product` | Product dimension |
| `vw_dim_household` | Household dimension with available demographic fields |
| `vw_dim_store` | Store dimension created from transaction store IDs |
| `vw_dim_retail_calendar` | Retail day and week dimension |
| `vw_department_performance` | Department-level sales, discount and estimated margin summary |
| `vw_product_performance` | Product-level performance and promotion-risk support |
| `vw_weekly_sales` | Weekly trend summary |
| `vw_customer_summary` | Household-level value summary |
| `vw_data_quality_overview` | Data-quality overview for methodology reporting |

These views prepare the data for Power BI without manually changing the raw source tables.
## Power BI Model Preparation

The household dimension view was refined before relationship modelling.

Instead of using only the demographic source table, `analytics.vw_dim_household` now starts from all distinct transaction households and then joins to the available demographic data. This keeps households without demographic records in the model and labels missing attributes as `UNKNOWN`.

This supports a cleaner Power BI relationship between:

`Dim_Household[household_key]` → `Fact_Sales[household_key]`
