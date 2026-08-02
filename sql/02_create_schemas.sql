/*
02_create_schemas.sql

Purpose:
Create the main database schemas used by this project.

Schema plan:
- raw: source-style tables loaded from the CSV files
- ref: small reference and assumption tables created during the project
- analytics: cleaned views and reporting-ready objects for Power BI

Run note:
Run this script while connected to the grocery_retail_bi database.
*/

CREATE SCHEMA IF NOT EXISTS raw;

CREATE SCHEMA IF NOT EXISTS ref;

CREATE SCHEMA IF NOT EXISTS analytics;

COMMENT ON SCHEMA raw IS
'Source-style tables loaded from the dunnhumby CSV files.';

COMMENT ON SCHEMA ref IS
'Reference and assumption tables, including estimated margin assumptions.';

COMMENT ON SCHEMA analytics IS
'Cleaned analytical views and reporting-ready objects used by Power BI.';
