# Data Quality Findings

## Purpose

This document summarizes the first round of data-quality checks completed after loading the raw files into PostgreSQL.

The goal of this step was to understand the source data before creating cleaned SQL views. I did not want to clean or filter records without first checking the structure, row counts, relationships and business meaning of the fields.

## Source Tables Checked

| Table | Role |
|---|---|
| `raw.transaction_data` | Main product-level transaction data |
| `raw.product` | Product hierarchy and category information |
| `raw.hh_demographic` | Available household demographic attributes |
| `ref.store_lookup` | Store lookup generated from transaction store IDs |

## Row Count Validation

The loaded PostgreSQL row counts were compared with the earlier source profiling baseline.

| Table | Expected Rows | Database Rows | Status |
|---|---:|---:|---|
| `raw.transaction_data` | 2,595,732 | 2,595,732 | Pass |
| `raw.product` | 92,353 | 92,353 | Pass |
| `raw.hh_demographic` | 801 | 801 | Pass |

This confirms that the required raw files were loaded into PostgreSQL successfully.

## Department-Level Preview

A department-level transaction and sales summary was reviewed after joining transactions to product data.

The largest departments included:

| Department | Transaction Rows | Total Sales |
|---|---:|---:|
| `GROCERY` | 1,646,076 | 4,093,814.14 |
| `DRUG GM` | 277,232 | 1,055,358.03 |
| `PRODUCE` | 257,290 | 557,452.11 |
| `MEAT` | 88,416 | 548,786.81 |
| `KIOSK-GAS` | 22,059 | 544,222.28 |
| `MEAT-PCKGD` | 111,957 | 412,436.77 |
| `DELI` | 62,787 | 260,866.51 |
| `PASTRY` | 38,179 | 121,739.86 |

This result is useful for the next stage because department performance will guide the margin-assumption table and the executive dashboard design.

## Key Data-Quality Decisions

### 1. Preserve the raw layer

The raw tables should remain close to the original source files. Any cleaning or business logic will be added through SQL views rather than manually changing the source records.

### 2. Treat discount values carefully

Discount fields may use a negative-value convention. In the reporting layer, discount amount should be shown as a positive business value using absolute values.

### 3. Keep unmatched demographics

The household demographic file is smaller than the transaction table, so some transaction households may not have demographic details. These records should not be removed. They should be labelled as `Unknown` in the analytical model.

### 4. Build cleaned views next

The next step is to create SQL views that prepare Power BI-ready tables, including:

- cleaned transaction fact view
- product dimension view
- household dimension view
- store dimension view
- retail day/week dimension view

## Notes

This document is intentionally concise because it is public-facing. The detailed SQL checks are stored in `sql/07_data_quality_checks.sql`.