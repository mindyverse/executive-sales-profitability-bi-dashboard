# Case Study: Executive Sales & Estimated Margin BI Dashboard

## Why I built this

I wanted to build a project that felt closer to real BI work than a simple dashboard made from one spreadsheet.

For this project, I used grocery retail transaction data and built the workflow from the ground up. I loaded the data into PostgreSQL, checked it with SQL, prepared analytics views, connected the model to Power BI and designed a six-page dashboard.

The main idea was simple: if a retail manager opened this report, they should be able to understand sales, baskets, stores, product categories, discounts and household behaviour without needing to look through raw tables.

## Project summary

This project uses the dunnhumby Complete Journey dataset, which includes grocery retail transaction data.

The main files I used were:

- `transaction_data.csv`
- `product.csv`
- `hh_demographic.csv`

The transaction file contains 2,595,732 rows, so this was a good opportunity to practise working with a larger dataset instead of a small sample file.

I kept the raw data and PBIX file local. The public GitHub repository includes the SQL scripts, documentation, screenshots and portfolio page.

## The important limitation

The dataset includes sales and discount information, but it does not include actual product cost.

Because of that, I did not present the dashboard as exact profit analysis. Instead, I created department-level margin assumptions and used them to calculate estimated gross margin.

I kept this wording visible because I wanted the project to be honest. Estimated margin is useful for comparison, but it should not be treated as accounting profit.

## Tools used

| Tool | Purpose |
|---|---|
| PostgreSQL | Stored the raw data and organised the database |
| SQL | Loaded, checked and prepared the reporting views |
| Power BI | Built the model, measures and dashboard pages |
| VS Code | Wrote SQL scripts and documentation |
| Git and GitHub | Tracked the project and published the repository |
| GitHub Pages | Published the online portfolio page |

## How I structured the database

I used three schemas in PostgreSQL:

| Schema | Purpose |
|---|---|
| `raw` | Original loaded tables |
| `ref` | Reference tables, including store lookup and margin assumptions |
| `analytics` | Clean views prepared for Power BI |

This helped keep the project organised. The raw layer stayed close to the original files, while the analytics layer was easier to use in Power BI.

## Data checks I completed

Before building the report, I checked the data for issues such as:

- row counts after loading
- missing key fields
- zero quantity rows
- zero sales value rows
- product join coverage
- household demographic coverage
- unusual discount values

I also compared key Power BI measures against SQL results so I could trust the main numbers used in the dashboard.

## Power BI model

The Power BI model follows a star-schema-style structure.

The main fact table is `Fact_Sales`. It connects to dimensions for products, stores, households and the retail calendar.

This made the model easier to understand and helped keep the filters predictable across the report pages.

## Main dashboard pages

The final report has six pages:

1. Executive Overview
2. Product and Category Performance
3. Store and Time Performance
4. Discount and Promotion Analysis
5. Customer and Household Performance
6. Data Quality and Methodology

Each page was designed around a slightly different business question, instead of showing random charts.

## Main measures

The report includes measures such as:

- Total Sales
- Units Sold
- Basket Count
- Average Basket Value
- Total Discount Amount
- Discount Pressure %
- Estimated Gross Margin
- Estimated Margin %
- Sales per Household
- Baskets per Household
- Data Quality Pass %
- Demographic Coverage %

## Dashboard design

I wanted the dashboard to feel clean, calm and easy to read.

The final design uses a soft background, rounded white cards, simple typography, blue accents and enough spacing between visuals. I kept the layout minimal because the purpose of the project is to show the analysis clearly, not to make the page feel crowded.

## What I found interesting

A few things stood out while building the report:

- Grocery was the biggest contributor to sales.
- Discount pressure was not evenly spread across products and departments.
- Some high-sales products also had higher discount pressure, so I marked them for review.
- Household demographics were only available for part of the data.
- Keeping missing demographic values as `UNKNOWN` was better than removing those transactions.

The discount review flag is only a simple rule to help identify products that may need a closer look. It is not a final pricing recommendation.

## What I learned

This project helped me connect the full BI process together.

I practised:

- setting up a clean project folder
- loading CSV data into PostgreSQL
- checking row counts and data quality
- preparing SQL views for reporting
- building a Power BI model
- writing DAX measures
- validating dashboard numbers
- designing a report for business users
- documenting assumptions clearly

The biggest lesson was learning to be careful with language. Since the dataset does not include actual cost, I could not honestly call the margin result true profit. Using estimated margin made the project more realistic and more trustworthy.

## What I would improve next

If I continued this project, I would improve it by:

- adding actual product cost data if it became available
- adding deeper customer segmentation
- comparing discount levels before and after promotions
- publishing an interactive version through Power BI Service
- creating a shorter executive summary for non-technical viewers

## Project links

Live portfolio:

`https://mindyverse.github.io/executive-sales-profitability-bi-dashboard/`

GitHub repository:

`https://github.com/mindyverse/executive-sales-profitability-bi-dashboard`