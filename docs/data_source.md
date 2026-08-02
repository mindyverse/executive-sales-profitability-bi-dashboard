# Dataset Source — dunnhumby The Complete Journey

## Dataset Name

dunnhumby — The Complete Journey

## Primary Source

dunnhumby Source Files.

The dataset was downloaded from the official dunnhumby source-files page for personal, educational, and portfolio analysis.

## Dataset Context

The dataset represents household-level grocery retail transactions over approximately two years for 2,500 frequent-shopper households.

It includes transaction, product, household demographic, campaign, coupon, and promotional information across multiple related files.

## Version 1 Project Scope

The initial dashboard version will use:

- `transaction_data.csv`
- `product.csv`
- `hh_demographic.csv`
- A custom department-level margin assumption table created during the project

Campaign, coupon, redemption, and causal promotion files are retained in the raw source but are outside the initial dashboard scope.

## Raw-Data Handling

- The original downloaded archive is retained without manual modification.
- Extracted CSV files are retained in the local raw-data layer.
- Raw dataset files are excluded from Git version control and are not uploaded to GitHub.
- Transformations will be performed through documented SQL scripts and views.

## Profitability Limitation

The source dataset does not contain actual product cost or cost-of-goods-sold data.

Therefore, the dashboard will calculate an estimated gross margin proxy using clearly documented department-level margin assumptions. It will not claim to report exact accounting profit.

## Reproduction Note

Anyone reproducing this project must obtain The Complete Journey dataset separately from the official dunnhumby source-files page and place the required CSV files in the local `data/raw` directory.