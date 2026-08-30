-- ================================
-- Adventure Works Sales Analysis
-- Database: AdventureWorks_DB
-- ================================


-- 1. Overview Metrics
SELECT 
    COUNT(*) AS TotalOrders,
    COUNT(DISTINCT OrderNumber) AS UniqueOrders,
    SUM(OrderQuantity) AS TotalQuantitySold
FROM Sales;


-- 2. Sales Performance by Year
SELECT 
    YEAR(OrderDate) AS OrderYear,
    COUNT(*) AS Orders,
    SUM(OrderQuantity) AS QuantitySold
FROM Sales
GROUP BY YEAR(OrderDate)
ORDER BY OrderYear;


-- 3. Top 10 Best Selling Products
SELECT TOP 10
    p.ProductName,
    SUM(s.OrderQuantity) AS QuantitySold
FROM Sales s
JOIN Product_Lookup p ON s.ProductKey = p.ProductKey
GROUP BY p.ProductName
ORDER BY QuantitySold DESC;


-- 4. Sales by Product Category
SELECT 
    c.CategoryName,
    SUM(s.OrderQuantity) AS QuantitySold
FROM Sales s
JOIN Product_Lookup p ON s.ProductKey = p.ProductKey
JOIN Product_Subcategories sc ON p.ProductSubcategoryKey = sc.ProductSubcategoryKey
JOIN Product_Categories c ON sc.ProductCategoryKey = c.ProductCategoryKey
GROUP BY c.CategoryName
ORDER BY QuantitySold DESC;


-- 5. Sales by Country
SELECT 
    t.Country,
    COUNT(*) AS Orders,
    SUM(s.OrderQuantity) AS QuantitySold
FROM Sales s
JOIN Territory t ON s.TerritoryKey = t.SalesTerritoryKey
GROUP BY t.Country
ORDER BY QuantitySold DESC;


-- 6. Monthly Trend
SELECT 
    YEAR(OrderDate) AS OrderYear,
    MONTH(OrderDate) AS OrderMonth,
    DATENAME(MONTH, OrderDate) AS MonthName,
    SUM(OrderQuantity) AS QuantitySold
FROM Sales
GROUP BY YEAR(OrderDate), MONTH(OrderDate), DATENAME(MONTH, OrderDate)
ORDER BY OrderYear, OrderMonth;


-- 7. Top 10 Customers by Number of Orders
SELECT TOP 10
    c.FirstName + ' ' + c.LastName AS CustomerName,
    COUNT(*) AS Orders,
    SUM(s.OrderQuantity) AS QuantityBought
FROM Sales s
JOIN Customer_Lookup c ON s.CustomerKey = c.CustomerKey
GROUP BY c.FirstName, c.LastName
ORDER BY Orders DESC;


-- 8. Returns Overview
SELECT 
    COUNT(*) AS ReturnRecords,
    SUM(ReturnQuantity) AS TotalReturnedQty
FROM Returns;


-- 9. Top Returned Products
SELECT TOP 10
    p.ProductName,
    SUM(r.ReturnQuantity) AS ReturnedQty
FROM Returns r
JOIN Product_Lookup p ON r.ProductKey = p.ProductKey
GROUP BY p.ProductName
ORDER BY ReturnedQty DESC;


-- 10. Overall Return Rate
SELECT 
    (SELECT SUM(OrderQuantity) FROM Sales) AS TotalSold,
    (SELECT SUM(ReturnQuantity) FROM Returns) AS TotalReturned,
    CAST(
        (SELECT SUM(ReturnQuantity) FROM Returns) * 100.0 / 
        (SELECT SUM(OrderQuantity) FROM Sales) 
        AS DECIMAL(5,2)
    ) AS ReturnRatePct;



-- =============================================
-- View: vw_SalesDetails (already created)
-- =============================================
/*
CREATE VIEW vw_SalesDetails AS
SELECT 
    s.OrderDate,
    s.OrderNumber,
    s.OrderQuantity,
    p.ProductName,
    c.CategoryName,
    t.Country
FROM Sales s
JOIN Product_Lookup p ON s.ProductKey = p.ProductKey
JOIN Product_Subcategories sc ON p.ProductSubcategoryKey = sc.ProductSubcategoryKey
JOIN Product_Categories c ON sc.ProductCategoryKey = c.ProductCategoryKey
JOIN Territory t ON s.TerritoryKey = t.SalesTerritoryKey;
*/
  