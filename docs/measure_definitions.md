# Measure Definitions

## Purpose

This document explains the main Power BI measures used in the dashboard.

The goal is to keep the KPI definitions clear enough that someone reviewing the project can understand what each number means without opening the Power BI file.

## Core Measures

| Measure | Definition |
|---|---|
| `Total Sales` | Sum of recorded transaction sales value |
| `Units Sold` | Sum of product quantity sold |
| `Basket Count` | Distinct count of shopping basket IDs |
| `Transaction Rows` | Count of transaction-level rows in the sales fact table |
| `Average Basket Value` | Total Sales divided by Basket Count |
| `Total Discount Amount` | Sum of positive discount amounts prepared in SQL |
| `Estimated Gross Shelf Value` | Sales value plus discount amount |
| `Discount Pressure %` | Total Discount Amount divided by Estimated Gross Shelf Value |
| `Estimated Gross Margin` | Sum of estimated gross margin prepared from department assumptions |
| `Estimated Margin %` | Estimated Gross Margin divided by Total Sales |
| `Household Count` | Distinct count of households in the sales fact table |
| `Store Count` | Distinct count of stores in the sales fact table |
| `Product Count` | Distinct count of products sold |
| `Average Selling Price` | Total Sales divided by Units Sold |
| `Average Units per Basket` | Units Sold divided by Basket Count |
| `Sales per Household` | Total Sales divided by Household Count |
| `Discounted Transaction Rows` | Transaction rows where discount amount is greater than zero |
| `Discounted Transaction Row %` | Discounted Transaction Rows divided by Transaction Rows |
| `Flagged Transaction Rows` | Rows flagged by the SQL quality logic |
| `Flagged Transaction Row %` | Flagged Transaction Rows divided by Transaction Rows |

## Profitability Note

The dataset does not contain actual product cost.

For that reason, the dashboard uses an estimated gross margin measure based on department-level assumptions. This should be read as a profitability proxy, not exact accounting profit.

## Validation

The DAX measures were checked against a SQL baseline query stored in:

`sql/12_validate_powerbi_kpis.sql`