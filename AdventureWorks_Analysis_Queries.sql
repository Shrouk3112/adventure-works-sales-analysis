/* Adventure Works sales analysis | SQL Server (T-SQL)
   Prerequisites, this script does not import CSV files or create dbo.Sales:
   dbo.Sales: combined 2020, 2021 and January-June 2022 sales CSVs.
   dbo.Product_Lookup: Product Lookup.csv
   dbo.Product_Subcategories: Product Subcategories Lookup.csv
   dbo.Product_Categories: Product Categories Lookup.csv
   dbo.Customer_Lookup: Customer Lookup.csv, with non-numeric footer keys removed.
   dbo.Territory: Territory Lookup.csv
   dbo.Returns: Returns Data.csv
   Import dates as DATE, keys and quantities as integers, prices/costs as decimals.
   The sales grain is one order line. COUNT(*) is NOT an order count.
   Price and cost are product lookup values; profit below is estimated gross profit.
   This replacement is reviewed statically and against the public CSV data;
   it still needs execution in the owner's SQL Server environment.
*/
SET NOCOUNT ON;

-- 0. Quality checks. Investigate any returned key/quantity issues before analysis.
SELECT MIN(OrderDate) AS FirstSalesDate, MAX(OrderDate) AS LastSalesDate,
       COUNT(*) AS OrderLines, COUNT(DISTINCT OrderNumber) AS DistinctOrders
FROM dbo.Sales;

SELECT ProductKey, COUNT(*) AS KeyRows
FROM dbo.Product_Lookup GROUP BY ProductKey HAVING COUNT(*) > 1;
SELECT TRY_CONVERT(int, CustomerKey) AS CustomerKey, COUNT(*) AS KeyRows
FROM dbo.Customer_Lookup
WHERE TRY_CONVERT(int, CustomerKey) IS NOT NULL
GROUP BY TRY_CONVERT(int, CustomerKey) HAVING COUNT(*) > 1;
SELECT SalesTerritoryKey, COUNT(*) AS KeyRows
FROM dbo.Territory GROUP BY SalesTerritoryKey HAVING COUNT(*) > 1;

SELECT COUNT(*) AS InvalidOrMissingSalesKeysOrQuantities
FROM dbo.Sales s
WHERE s.OrderNumber IS NULL OR s.OrderDate IS NULL
   OR s.OrderQuantity IS NULL OR s.OrderQuantity <= 0
   OR NOT EXISTS (SELECT 1 FROM dbo.Product_Lookup p WHERE p.ProductKey = s.ProductKey)
   OR NOT EXISTS (SELECT 1 FROM dbo.Customer_Lookup c
                  WHERE TRY_CONVERT(int, c.CustomerKey) = s.CustomerKey)
   OR NOT EXISTS (SELECT 1 FROM dbo.Territory t WHERE t.SalesTerritoryKey = s.TerritoryKey);

-- 1. Overall metrics. Explicitly separate lines, orders, customers and units.
SELECT COUNT(*) AS OrderLines,
       COUNT(DISTINCT s.OrderNumber) AS DistinctOrders,
       COUNT(DISTINCT s.CustomerKey) AS PurchasingCustomers,
       SUM(CAST(s.OrderQuantity AS bigint)) AS UnitsSold,
       SUM(s.OrderQuantity * CAST(p.ProductPrice AS decimal(19,4))) AS Revenue,
       SUM(s.OrderQuantity * (CAST(p.ProductPrice AS decimal(19,4))
                           - CAST(p.ProductCost AS decimal(19,4)))) AS GrossProfit,
       100.0 * SUM(s.OrderQuantity * (CAST(p.ProductPrice AS decimal(19,4))
                                   - CAST(p.ProductCost AS decimal(19,4))))
       / NULLIF(SUM(s.OrderQuantity * CAST(p.ProductPrice AS decimal(19,4))), 0) AS GrossMarginPct,
       SUM(s.OrderQuantity * CAST(p.ProductPrice AS decimal(19,4)))
       / NULLIF(COUNT(DISTINCT s.OrderNumber), 0) AS AverageOrderValue
FROM dbo.Sales s
JOIN dbo.Product_Lookup p ON p.ProductKey = s.ProductKey;

-- 2. Revenue and quantity by year. 2022 contains January-June only.
SELECT YEAR(s.OrderDate) AS SalesYear,
       MIN(s.OrderDate) AS FirstIncludedDate, MAX(s.OrderDate) AS LastIncludedDate,
       COUNT(*) AS OrderLines, COUNT(DISTINCT s.OrderNumber) AS DistinctOrders,
       SUM(CAST(s.OrderQuantity AS bigint)) AS UnitsSold,
       SUM(s.OrderQuantity * CAST(p.ProductPrice AS decimal(19,4))) AS Revenue
FROM dbo.Sales s
JOIN dbo.Product_Lookup p ON p.ProductKey = s.ProductKey
GROUP BY YEAR(s.OrderDate)
ORDER BY SalesYear;

-- 3. Top ten products by units, not by revenue.
SELECT TOP (10) p.ProductKey, p.ProductName,
       SUM(CAST(s.OrderQuantity AS bigint)) AS UnitsSold,
       SUM(s.OrderQuantity * CAST(p.ProductPrice AS decimal(19,4))) AS Revenue
FROM dbo.Sales s
JOIN dbo.Product_Lookup p ON p.ProductKey = s.ProductKey
GROUP BY p.ProductKey, p.ProductName
ORDER BY UnitsSold DESC, p.ProductKey;

-- 4. Revenue, gross profit and units by category.
SELECT c.CategoryName,
       SUM(CAST(s.OrderQuantity AS bigint)) AS UnitsSold,
       SUM(s.OrderQuantity * CAST(p.ProductPrice AS decimal(19,4))) AS Revenue,
       SUM(s.OrderQuantity * (CAST(p.ProductPrice AS decimal(19,4))
                           - CAST(p.ProductCost AS decimal(19,4)))) AS GrossProfit
FROM dbo.Sales s
JOIN dbo.Product_Lookup p ON p.ProductKey = s.ProductKey
JOIN dbo.Product_Subcategories sc ON sc.ProductSubcategoryKey = p.ProductSubcategoryKey
JOIN dbo.Product_Categories c ON c.ProductCategoryKey = sc.ProductCategoryKey
GROUP BY c.CategoryName
ORDER BY Revenue DESC;

-- 5. Country performance. An order count is distinct within each country.
SELECT t.Country, COUNT(*) AS OrderLines,
       COUNT(DISTINCT s.OrderNumber) AS DistinctOrders,
       SUM(CAST(s.OrderQuantity AS bigint)) AS UnitsSold,
       SUM(s.OrderQuantity * CAST(p.ProductPrice AS decimal(19,4))) AS Revenue
FROM dbo.Sales s
JOIN dbo.Territory t ON t.SalesTerritoryKey = s.TerritoryKey
JOIN dbo.Product_Lookup p ON p.ProductKey = s.ProductKey
GROUP BY t.Country
ORDER BY Revenue DESC;

-- 6. Monthly trend, ordered chronologically.
SELECT YEAR(s.OrderDate) AS SalesYear, MONTH(s.OrderDate) AS SalesMonth,
       COUNT(DISTINCT s.OrderNumber) AS DistinctOrders,
       SUM(CAST(s.OrderQuantity AS bigint)) AS UnitsSold,
       SUM(s.OrderQuantity * CAST(p.ProductPrice AS decimal(19,4))) AS Revenue
FROM dbo.Sales s
JOIN dbo.Product_Lookup p ON p.ProductKey = s.ProductKey
GROUP BY YEAR(s.OrderDate), MONTH(s.OrderDate)
ORDER BY SalesYear, SalesMonth;

-- 7. Customers ranked by DISTINCT orders, with key to avoid merging namesakes.
SELECT TOP (10) s.CustomerKey, c.FirstName, c.LastName,
       COUNT(DISTINCT s.OrderNumber) AS DistinctOrders,
       SUM(CAST(s.OrderQuantity AS bigint)) AS UnitsBought
FROM dbo.Sales s
JOIN dbo.Customer_Lookup c ON TRY_CONVERT(int, c.CustomerKey) = s.CustomerKey
GROUP BY s.CustomerKey, c.FirstName, c.LastName
ORDER BY DistinctOrders DESC, s.CustomerKey;

-- 8. Returns overview: records and units are different measures.
SELECT COUNT(*) AS ReturnRecords,
       SUM(CAST(ReturnQuantity AS bigint)) AS ReturnedUnits
FROM dbo.Returns;

-- 9. Highest returned-unit counts. This is not a ranking by return rate.
SELECT TOP (10) p.ProductKey, p.ProductName,
       SUM(CAST(r.ReturnQuantity AS bigint)) AS ReturnedUnits
FROM dbo.Returns r
JOIN dbo.Product_Lookup p ON p.ProductKey = r.ProductKey
GROUP BY p.ProductKey, p.ProductName
ORDER BY ReturnedUnits DESC, p.ProductKey;

-- 10. Overall returned-to-sold unit ratio over the supplied reporting period.
-- Returns have no original OrderNumber; this is NOT percent of orders returned.
SELECT sold.UnitsSold, ret.ReturnedUnits,
       CAST(100.0 * ret.ReturnedUnits / NULLIF(sold.UnitsSold, 0)
            AS decimal(9,4)) AS ReturnedToSoldUnitRatioPct
FROM (SELECT SUM(CAST(OrderQuantity AS bigint)) AS UnitsSold FROM dbo.Sales) sold
CROSS JOIN (SELECT SUM(CAST(ReturnQuantity AS bigint)) AS ReturnedUnits FROM dbo.Returns) ret;

-- 11. Comparable January-June periods. Do not compare half of 2022 to a full year.
SELECT YEAR(s.OrderDate) AS SalesYear,
       SUM(s.OrderQuantity * CAST(p.ProductPrice AS decimal(19,4))) AS FirstHalfRevenue,
       SUM(CAST(s.OrderQuantity AS bigint)) AS FirstHalfUnitsSold
FROM dbo.Sales s
JOIN dbo.Product_Lookup p ON p.ProductKey = s.ProductKey
WHERE MONTH(s.OrderDate) BETWEEN 1 AND 6
GROUP BY YEAR(s.OrderDate)
ORDER BY SalesYear;

-- 12. Education totals and revenue per purchasing customer.
-- These are descriptive comparisons, not causal effects of education.
SELECT c.EducationLevel,
       COUNT(DISTINCT s.CustomerKey) AS PurchasingCustomers,
       SUM(s.OrderQuantity * CAST(p.ProductPrice AS decimal(19,4))) AS Revenue,
       SUM(s.OrderQuantity * CAST(p.ProductPrice AS decimal(19,4)))
       / NULLIF(COUNT(DISTINCT s.CustomerKey), 0) AS RevenuePerPurchasingCustomer
FROM dbo.Sales s
JOIN dbo.Customer_Lookup c ON TRY_CONVERT(int, c.CustomerKey) = s.CustomerKey
JOIN dbo.Product_Lookup p ON p.ProductKey = s.ProductKey
GROUP BY c.EducationLevel
ORDER BY Revenue DESC;
