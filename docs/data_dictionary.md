# Initial Data Dictionary

## Purpose

This document records the meaning and analytical role of the required raw dataset files and their important columns.

The exact raw column names and casing must be confirmed against `notes/raw_column_inventory.csv`. Raw source columns will not be renamed manually inside the CSV files.

## Table Summary

| Source File | Analytical Role | Expected Grain |
|---|---|---|
| `transaction_data.csv` | Core sales transaction fact source | One product-level transaction line within a shopping basket |
| `product.csv` | Product hierarchy and descriptive attributes | One row per product identifier |
| `hh_demographic.csv` | Available household demographic attributes | One row per household represented in the demographic sample |
| Custom margin assumption table | Department-level estimated margin assumptions | One row per standardized department |

## Transaction Data — Important Business Fields

Use the actual names shown in `raw_column_inventory.csv`.

| Business Concept | Meaning | Intended Analytical Use |
|---|---|---|
| Basket identifier | Unique shopping basket or visit identifier | Distinct basket count and average basket value |
| Household identifier | Customer-household reference | Household value and repeat-purchase analysis |
| Product identifier | Product purchased in the transaction | Join to product dimension |
| Store identifier | Store where the transaction occurred | Store ranking and performance |
| Day | Retail day sequence | Time ordering and date dimension construction |
| Week number | Retail week sequence | Weekly sales and seasonality analysis |
| Quantity | Number of product units purchased | Units-sold measure |
| Sales value | Revenue recorded for the transaction line | Total sales measure |
| Retail discount | Retail-level price reduction | Discount-pressure analysis |
| Coupon discount | Coupon-related price reduction | Promotion analysis |
| Coupon match discount | Retailer coupon-match reduction | Promotion analysis |
| Transaction time | Time of purchase where available | Optional daypart analysis |

## Product Data — Important Business Fields

| Business Concept | Meaning | Intended Analytical Use |
|---|---|---|
| Product identifier | Unique product reference | Product dimension key |
| Department | High-level retail department | Department performance and margin assumptions |
| Brand | Brand classification | Brand contribution analysis |
| Commodity | Product category or commodity grouping | Category performance |
| Sub-commodity | More detailed product grouping | Detailed product analysis |
| Manufacturer | Manufacturer reference | Manufacturer contribution analysis |
| Product size | Source description of product size | Product description and optional normalization |

## Household Demographic Data — Important Business Fields

| Business Concept | Meaning | Intended Analytical Use |
|---|---|---|
| Household identifier | Household reference | Join to transaction households |
| Age group | Household age classification | Customer segmentation |
| Marital status | Household marital-status classification | Customer segmentation |
| Income group | Household income band | Value contribution by income segment |
| Homeownership | Homeownership classification | Customer segmentation |
| Household composition | Household structure | Customer profile analysis |
| Household size | Household-size band | Customer segmentation |
| Children category | Children-related household category | Family-segment analysis |

## Important Modelling Notes

1. The transaction source is the fact-style table.
2. The product source is a dimension-style table.
3. Household demographics may not exist for every transaction household.
4. Missing household attributes should normally be represented as `Unknown` in the analytical model rather than silently removing transactions.
5. Product cost does not exist in the source dataset.
6. Profitability will therefore be represented using a documented estimated gross-margin proxy.
7. Exact data types, nullability and key uniqueness will be confirmed through PostgreSQL profiling.