-- 1) Query to segment customers based on age

SELECT 
    c.CustomerKey,
    TIMESTAMPDIFF(YEAR, c.Birthday, CURDATE()) AS Age,
    CASE
        WHEN TIMESTAMPDIFF(YEAR, c.Birthday, CURDATE()) BETWEEN 20 AND 29 THEN '20s'
        WHEN TIMESTAMPDIFF(YEAR, c.Birthday, CURDATE()) BETWEEN 30 AND 39 THEN '30s'
        WHEN TIMESTAMPDIFF(YEAR, c.Birthday, CURDATE()) BETWEEN 40 AND 49 THEN '40s'
        WHEN TIMESTAMPDIFF(YEAR, c.Birthday, CURDATE()) BETWEEN 50 AND 59 THEN '50s'
        WHEN TIMESTAMPDIFF(YEAR, c.Birthday, CURDATE()) BETWEEN 60 AND 69 THEN '60s'
        WHEN TIMESTAMPDIFF(YEAR, c.Birthday, CURDATE()) >= 70 THEN 'Above 70'
        ELSE 'Unknown'
    END AS AgeGroup
FROM 
    Customers c;
    
-- 2) Query to segment customers based on frequency of orders
    
WITH CustomerOrders AS (
    SELECT 
        s.CustomerKey,
        COUNT(s.`Order Number`) AS OrderCount
    FROM 
        Sales s
    GROUP BY 
        s.CustomerKey
)
SELECT 
    c.CustomerKey,
    COALESCE(co.OrderCount, 0) AS OrderCount,
    CASE
        WHEN COALESCE(co.OrderCount, 0) > 10 THEN 'VIP Customer'
        WHEN COALESCE(co.OrderCount, 0) BETWEEN 5 AND 10 THEN 'Frequent Buyer'
        WHEN COALESCE(co.OrderCount, 0) BETWEEN 1 AND 4 THEN 'Moderate Buyer'
        ELSE 'No Orders'
    END AS CustomerOrderingType
FROM 
    Customers c
LEFT JOIN
    CustomerOrders co ON c.CustomerKey = co.CustomerKey;
    
-- 3) Query to calculate total revenue and profit for each customer

WITH CustomerRevenue AS (
    SELECT 
        s.CustomerKey,
        ROUND(SUM(p.`Unit Price USD` * s.Quantity), 2) AS TotalRevenue,
	    ROUND(SUM((p.`Unit Price USD` - p.`Unit Cost USD`)* s.Quantity), 2) As TotalProfit
    FROM 
        Sales s
    JOIN 
        Products p ON s.ProductKey = p.ProductKey
    GROUP BY 
        s.CustomerKey
)
SELECT 
    c.CustomerKey,
    COALESCE(cr.TotalRevenue, 0) AS TotalRevenue,
    COALESCE(cr.TotalProfit, 0) AS TotalProfit	
FROM 
    Customers c
LEFT JOIN
    CustomerRevenue cr ON c.CustomerKey = cr.CustomerKey;

-- 4) Query to calculates the average order value for each customer

SELECT 
    c.CustomerKey, 
    c.Name, 
    AVG(p.`Revenue USD`) AS Average_Order_Value
FROM sales s
JOIN customers c ON s.CustomerKey = c.CustomerKey
JOIN products p ON s.ProductKey = p.ProductKey
GROUP BY c.CustomerKey, c.Name
ORDER BY Average_Order_Value DESC;

-- 5) Query to calculate total revenue and profit for each store

WITH SalesData AS (
    SELECT
        s.StoreKey,
        ROUND(SUM(p.`Unit Price USD` * s.Quantity), 2) AS TotalRevenue,
	    ROUND(SUM((p.`Unit Price USD` - p.`Unit Cost USD`)* s.Quantity), 2) As TotalProfit
    FROM
        sales s
    JOIN
        products p ON s.ProductKey = p.ProductKey
    GROUP BY
        s.StoreKey
)
SELECT
    s.StoreKey,
    TotalRevenue,
    TotalProfit
FROM
    SalesData s
JOIN
    stores st ON s.StoreKey = st.StoreKey
ORDER BY
    TotalRevenue DESC;
    
-- 6) Query to calculate total revenue and profit for each Product Category

SELECT
        p.CategoryKey,
        ROUND(SUM((pr.`Unit Price USD` - pr.`Unit Cost USD`) * s.Quantity), 2) AS ProfitUSD,
        ROUND(SUM((pr.`Unit Price USD`) * s.Quantity), 2) AS RevenueUSD
    FROM
        Sales s
    JOIN
        Products pr ON s.ProductKey = pr.ProductKey
    JOIN
        Products p ON pr.CategoryKey = p.CategoryKey
    GROUP BY
        p.CategoryKey;
      
-- 7) Query to calculate total revenue and profit for each Product Subcategory

SELECT
    pr.SubcategoryKey,
    ROUND(SUM((pr.`Unit Price USD` - pr.`Unit Cost USD`) * s.Quantity), 2) AS ProfitUSD,
    ROUND(SUM(pr.`Unit Price USD` * s.Quantity), 2) AS RevenueUSD
FROM
    Sales s
JOIN
    Products pr ON s.ProductKey = pr.ProductKey
GROUP BY
    pr.SubcategoryKey;

-- 8) Query to identify sales trends by month to highlight any seasonality in sales

SELECT 
    MONTH(s.`Order Date`) AS Month, 
    ROUND(SUM(p.`Revenue USD`), 2) AS Total_Sales
FROM sales s
JOIN products p ON s.ProductKey = p.ProductKey
GROUP BY MONTH(s.`Order Date`)
ORDER BY Total_Sales DESC;

-- 9) Query to calculate total sales by store size

SELECT 
    st.StoreKey, 
    st.S_Country, 
    st.`Square Meters`, 
    ROUND(SUM(p.`Revenue USD`), 2) AS Total_Sales
FROM sales s
JOIN stores st ON s.StoreKey = st.StoreKey
JOIN products p ON s.ProductKey = p.ProductKey
GROUP BY st.StoreKey, st.S_Country, st.`Square Meters`
ORDER BY Total_Sales DESC;

-- 10) Online Store number of customers, orders and revenue

SELECT
	StoreKey,
        COUNT(DISTINCT s.CustomerKey) AS NumberOfCustomers,
        COUNT(s.`Order Number`) AS NumberOfOrders,
        ROUND(SUM(p.`Unit Price USD` * s.Quantity), 2) AS TotalRevenue
    FROM 
        Sales s
    JOIN 
        products p ON s.ProductKey = p.ProductKey
    WHERE 
        s.StoreKey = 0