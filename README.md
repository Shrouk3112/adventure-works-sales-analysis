# Adventure Works Sales Analysis

## Project overview

This project explores sales, gross profit, products, customers, territories and returns from **1 January 2020 to 30 June 2022** using SQL Server, Power BI, Excel and Python.

The sales data is at **order-line level**, not one row per order. Revenue and gross profit are calculated using the product lookup's unit price and unit cost. These are analytical estimates, not audited net profit figures.

This repository currently presents the Power BI dashboard through screenshots. A downloadable `.pbix` report is not included.

## Verified overall results

| Metric | Value | Definition |
|---|---:|---|
| Revenue | $24,914,586.82 | Quantity × product lookup price |
| Gross profit | $10,457,715.43 | Quantity × (lookup price − lookup cost) |
| Gross margin | 41.97% | Gross profit / revenue |
| Order lines | 56,046 | Rows in the combined sales table |
| Distinct orders | 25,164 | Distinct OrderNumber |
| Purchasing customers | 17,416 | Distinct CustomerKey in sales |
| Units sold | 84,174 | Sum of OrderQuantity |
| Average order value | $990.09 | Revenue / distinct orders |
| Returned units | 1,828 | Sum of ReturnQuantity |
| Returned-to-sold unit ratio | 2.17% | Returned units / units sold |

The returns data has no original order number. The ratio is a period-level unit comparison, not the percentage of orders returned or a matched sales-cohort return rate.

## Business questions

- What are the overall revenue, gross profit and order metrics?
- Which products, categories and countries contribute the most?
- How do revenue and unit volume change over time?
- Which customer groups contribute the most aggregate revenue?
- Which products have the highest returned-unit counts?

## Findings and interpretation

- Bikes contribute about $23.64M of revenue and $9.73M of gross profit, the largest amounts among the categories sold.
- The United States has the highest country revenue, about $7.94M, followed by Australia at $7.42M.
- Bachelor's degree customers contribute the most aggregate revenue ($8.42M), followed by Partial College ($6.53M) and Graduate Degree ($4.67M). Professional is the largest occupation group by aggregate revenue ($8.47M).
- These customer-group totals do not, by themselves, establish higher spending per customer or prove that education causes spending differences.
- Accessories account for 61.82% of returned units. This is their **share of returns**, not their category return rate. High-volume products can have many returns without having an unusually high return propensity.
- Full-year revenue increased from $6.40M in 2020 to $9.32M in 2021. January to June 2022 generated $9.19M. The 2022 data covers six months, so a full-year comparison would be misleading.
- Unit volume and revenue are different measures. The Python chart shows units, not revenue. Changes in product mix can make their trends differ.

## Recommendations

- Review inventory and commercial opportunities for the high-revenue Bikes category.
- Review Accessories returns relative to units sold, product mix and return reasons before deciding that quality is worse.
- Compare customer segments using both total revenue and revenue per purchasing customer before targeting marketing spend.
- Compare the same months across years when assessing growth, and keep the partial-2022 label visible.

## Power BI dashboard

The dashboard screenshots cover four pages. The reviewed report used distinct order numbers and distinct purchasing customer keys.

### Executive overview
![Executive overview](images/dashboard_executive_overview.png)

### Sales and product analysis
![Sales and product analysis](images/dashboard_sales_product_analysis.png)

### Customer analysis
![Customer analysis](images/dashboard_customer_analysis.png)

### Territory and returns
![Territory and returns](images/dashboard_territory_returns.png)

The reviewed Power BI model contained Sales and Returns fact tables, Customer, Territory and Date dimensions, and a Product → Subcategory → Category hierarchy. The separate category tables make the product hierarchy a snowflake extension rather than a completely flattened star schema.

Its measures included Revenue (Total Sales), Total Profit, Gross Margin, Distinct Orders, Purchasing Customers, Average Order Value, Total Quantity and Returned-to-Sold Unit Ratio. Date relationships connected OrderDate and ReturnDate to the Date table.

For year-over-year measures, compare equivalent completed periods. A prior-period value that is absent should be shown as blank rather than interpreted as zero growth.

## SQL, Excel and Python

- `AdventureWorks_Analysis_Queries.sql` expects imported SQL tables. It distinguishes order lines from orders and includes quantity-based and revenue-based breakdowns.
- The published Power Query combines the yearly sales tables. The SQL file should not be treated as a complete database creation or raw-file import pipeline.
- `AdventureWorks_Excel_Analysis.xlsx` contains a corrected summary plus January to June 2022 quantity pivots. Summary shows 25,164 distinct orders, 17,416 purchasing customers, 84,174 sold units and 1,828 returned units. The unit return ratio is displayed as 2.17%. The Insights sheet identifies the February dip and distinguishes partial-year 2022 from full-year 2020 and 2021.
- The workbook's 2022 units do not rise every month: February (6,828) is below January (7,020). Overall January to June volume rises, with a February dip.
- `adventure_works_analysis.py` aggregates quantity and produces a quantity chart. It requires pandas and matplotlib.

![Corrected Excel Summary](images/excel_summary.jpeg)
![Excel quantity pivots for January to June 2022](images/excel_pivot_analysis.png)
![Units sold by reporting period](images/sales_by_year.png)

## Data quality and limits

- The raw Customer Lookup CSV contains six blank/footer/non-customer records with non-numeric customer keys. The saved Power BI query removes the three marker records but still stores three unused blank/footer records. Remove all non-numeric customer-key records before importing this lookup into SQL; apply the same rule in Power Query when revising the report. No sales customer keys were missing from the valid lookup in this review.
- Prefix and some descriptive product fields have missing values. A missing optional description is not the same as a missing join key.
- Return records cannot be linked to individual original orders or customers with the supplied columns.
- Product prices and costs are lookup values, not transaction-level historical prices, discounts or operating expenses.
- The supplied files do not establish the causes of sales, returns or customer behavior.

## Files

```text
Raw_Data/                              Original CSV files
AdventureWorks_Analysis_Queries.sql     SQL analysis
AdventureWorks_Excel_Analysis.xlsx      Excel summary and 2022 pivots
adventure_works_analysis.py             Python quantity analysis
Data_Dictionary.md                     Table and column documentation
images/                                Screenshots and charts
README.md                              Project documentation
```

## How to use

1. View the four dashboard pages through the screenshots above. The downloadable Power BI report is not included in this repository.
2. For SQL, import the CSVs, combine yearly sales into `dbo.Sales`, and map the lookup tables to the names documented at the top of the SQL file. Importing and cleaning the source files is a prerequisite, not an automatic step in that script.
3. Open the Excel workbook to view the corrected Summary and Insights sheets and the January-June 2022 quantity pivots.
4. From the repository folder, install pandas and matplotlib, then run `python adventure_works_analysis.py`.

[Data dictionary](Data_Dictionary.md)
