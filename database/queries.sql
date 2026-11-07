-- ==============================================================================
-- PHARMACEUTICAL STORE MANAGEMENT SYSTEM - RETRIEVAL QUERIES
-- ==============================================================================
-- Database: Ph_Store
-- Project: B2B Pharmaceutical E-Commerce Platform
-- Total Queries: 34 (Categorized into 6 types)
-- ==============================================================================

USE Ph_Store;
GO

-- ==============================================================================
-- CATEGORY 1: BASIC QUERIES USING WHERE CLAUSE
-- ==============================================================================

-- Query 1: Retrieve medicines with price greater than 500
-- Purpose: Identify premium medicines for inventory management
SELECT * 
FROM Medicine 
WHERE mrp > 500;
GO

-- Query 2: Retrieve customers whose phone number ends with '5555'
-- Purpose: Customer segmentation based on phone number patterns
SELECT * 
FROM Customer 
WHERE phone LIKE '%5555';
GO

-- Query 3: Retrieve batches expiring within 6 months
-- Purpose: Identify medicines that need to be sold urgently to prevent wastage
SELECT * 
FROM Batch 
WHERE expiry_date BETWEEN GETDATE() AND DATEADD(MONTH, 6, GETDATE());
GO

-- Query 4: Retrieve sales with payment mode 'UPI'
-- Purpose: Analyze digital payment adoption trends
SELECT * 
FROM Payment 
WHERE payment_mode = 'UPI';
GO

-- Query 5: Retrieve employees with role 'PHARMACIST'
-- Purpose: Employee management and role-based reporting
SELECT * 
FROM User_Login 
WHERE role = 'PHARMACIST';
GO

-- Query 6: Retrieve medicines from 'Antibiotics' category
-- Purpose: Category-specific inventory analysis
SELECT m.* 
FROM Medicine m
JOIN Category c ON m.category_id = c.category_id
WHERE c.category_name = 'Antibiotics';
GO


-- ==============================================================================
-- CATEGORY 2: JOIN OR CARTESIAN PRODUCTS
-- ==============================================================================

-- Query 1: Retrieve customer details along with their order information
-- Purpose: Complete customer purchase history with payment details
SELECT 
    c.name AS Customer_Name, 
    c.phone, 
    s.sales_date, 
    s.total_amount,
    p.payment_mode
FROM Customer c
JOIN Sales s ON c.customer_id = s.customer_id
JOIN Payment p ON s.sales_id = p.sales_id;
GO

-- Query 2: Retrieve medicines along with their batch information and stock
-- Purpose: Inventory management with batch tracking
SELECT 
    m.name AS Medicine_Name,
    m.brand,
    b.batch_no,
    b.manufacture_date,
    b.expiry_date,
    b.stock_qty,
    b.selling_price
FROM Medicine m
JOIN Batch b ON m.medicine_id = b.medicine_id
WHERE b.expiry_date > GETDATE()
ORDER BY m.name;
GO

-- Query 3: Retrieve sales items with complete medicine and batch details
-- Purpose: Complete sales transaction details for reporting
SELECT 
    s.sales_id,
    s.sales_date,
    c.name AS Customer_Name,
    m.name AS Medicine_Name,
    m.brand,
    b.batch_no,
    si.quantity,
    si.selling_price,
    (si.quantity * si.selling_price) AS Line_Total
FROM Sales s
JOIN Sales_Items si ON s.sales_id = si.sales_id
JOIN Batch b ON si.batch_id = b.batch_id
JOIN Medicine m ON b.medicine_id = m.medicine_id
JOIN Customer c ON s.customer_id = c.customer_id;
GO

-- Query 4: Retrieve suppliers with their supplied medicines
-- Purpose: Supplier relationship management and procurement tracking
SELECT 
    s.supplier_name,
    s.contact_number,
    m.name AS Medicine_Name,
    p.purchase_date,
    p.total_amount
FROM Supplier s
JOIN Purchase p ON s.supplier_id = p.supplier_id
JOIN Purchase_Items pi ON p.purchase_id = pi.purchase_id
JOIN Medicine m ON pi.medicine_id = m.medicine_id
ORDER BY s.supplier_name;
GO

-- Query 5: Retrieve medicines with total quantity sold
-- Purpose: Identify best-selling medicines for stock optimization
SELECT 
    m.medicine_id,
    m.name AS Medicine_Name,
    m.brand,
    c.category_name,
    SUM(si.quantity) AS Total_Quantity_Sold
FROM Medicine m
JOIN Category c ON m.category_id = c.category_id
JOIN Batch b ON m.medicine_id = b.medicine_id
JOIN Sales_Items si ON b.batch_id = si.batch_id
GROUP BY m.medicine_id, m.name, m.brand, c.category_name
ORDER BY Total_Quantity_Sold DESC;
GO

-- Query 6: Retrieve employees who processed sales
-- Purpose: Employee performance tracking and commission calculation
SELECT 
    e.name AS Employee_Name,
    ul.role,
    COUNT(s.sales_id) AS Total_Sales_Processed,
    SUM(s.total_amount) AS Total_Revenue_Generated
FROM Employee e
JOIN User_Login ul ON e.employee_id = ul.user_id
JOIN Sales s ON e.employee_id = s.employee_id
GROUP BY e.name, ul.role
ORDER BY Total_Revenue_Generated DESC;
GO


-- ==============================================================================
-- CATEGORY 3: SET OPERATIONS
-- ==============================================================================

-- Query 1: Retrieve all medicines that have been sold but are out of stock
-- Purpose: Identify popular medicines needing urgent restocking
SELECT medicine_id 
FROM Batch 
WHERE stock_qty = 0

INTERSECT

SELECT DISTINCT b.medicine_id
FROM Batch b
JOIN Sales_Items si ON b.batch_id = si.batch_id;
GO

-- Query 2: Retrieve customers who have NOT made any purchases
-- Purpose: Identify inactive customers for re-engagement campaigns
SELECT * 
FROM Customer
WHERE customer_id NOT IN (
    SELECT DISTINCT customer_id FROM Sales
);
GO

-- Query 3: Retrieve all payment modes used - either in sales or supplier payments
-- Purpose: Analyze all payment methods across the business
SELECT payment_mode FROM Payment
UNION
SELECT payment_mode FROM Purchase;
GO

-- Query 4: Retrieve medicines that have been purchased but never sold
-- Purpose: Identify slow-moving inventory that needs promotion
SELECT DISTINCT medicine_id FROM Purchase_Items
EXCEPT
SELECT DISTINCT b.medicine_id 
FROM Batch b
JOIN Sales_Items si ON b.batch_id = si.batch_id;
GO

-- Query 5: Retrieve all usernames including duplicates from different roles
-- Purpose: Complete user audit across all roles
SELECT username FROM User_Login WHERE role = 'ADMIN'
UNION ALL
SELECT username FROM User_Login WHERE role = 'MANAGER'
UNION ALL
SELECT username FROM User_Login WHERE role = 'PHARMACIST';
GO

-- Query 6: Retrieve batches that are either expired or low stock
-- Purpose: Inventory alert system for quick action
SELECT batch_id, batch_no, 'EXPIRED' AS Issue 
FROM Batch 
WHERE expiry_date < GETDATE()

UNION

SELECT batch_id, batch_no, 'LOW_STOCK' AS Issue 
FROM Batch 
WHERE stock_qty < 20 AND expiry_date > GETDATE();
GO


-- ==============================================================================
-- CATEGORY 4: AGGREGATE FUNCTIONS
-- ==============================================================================

-- Query 1: Calculate total revenue from all sales
-- Purpose: Overall business revenue tracking
SELECT SUM(total_amount) AS Total_Revenue 
FROM Sales;
GO

-- Query 2: Find average selling price of medicines
-- Purpose: Pricing strategy analysis
SELECT AVG(selling_price) AS Average_Selling_Price 
FROM Batch;
GO

-- Query 3: Calculate maximum amount paid in a single transaction
-- Purpose: Identify largest transactions for VIP customer analysis
SELECT MAX(amount) AS Maximum_Payment 
FROM Payment;
GO

-- Query 4: Find minimum stock quantity across all batches
-- Purpose: Critical stock level monitoring
SELECT MIN(stock_qty) AS Minimum_Stock_Quantity 
FROM Batch 
WHERE expiry_date > GETDATE();
GO

-- Query 5: Count total number of sales transactions
-- Purpose: Sales volume metrics
SELECT COUNT(*) AS Total_Orders 
FROM Sales;
GO

-- Query 6: Calculate total quantity of medicines in stock
-- Purpose: Overall inventory level assessment
SELECT SUM(stock_qty) AS Total_Stock_Units 
FROM Batch 
WHERE expiry_date > GETDATE();
GO


-- ==============================================================================
-- CATEGORY 5: GROUP BY AND HAVING CLAUSE
-- ==============================================================================

-- Query 1: Group sales by payment mode and count orders
-- Purpose: Payment method preference analysis
SELECT 
    payment_mode, 
    COUNT(*) AS Number_of_Orders
FROM Payment
GROUP BY payment_mode
ORDER BY Number_of_Orders DESC;
GO

-- Query 2: Group medicines by category and calculate average MRP
-- Purpose: Category-wise pricing analysis
SELECT 
    c.category_name,
    AVG(m.mrp) AS Average_MRP,
    COUNT(m.medicine_id) AS Total_Medicines
FROM Medicine m
JOIN Category c ON m.category_id = c.category_id
GROUP BY c.category_name
ORDER BY Average_MRP DESC;
GO

-- Query 3: Group by category and show only categories with average price > 300
-- Purpose: Premium category identification
SELECT 
    c.category_name,
    AVG(m.mrp) AS Average_MRP
FROM Medicine m
JOIN Category c ON m.category_id = c.category_id
GROUP BY c.category_name
HAVING AVG(m.mrp) > 300;
GO

-- Query 4: Retrieve number of sales with amount > 1000, grouped by employee
-- Purpose: Employee performance on premium sales
SELECT 
    e.name AS Employee_Name,
    COUNT(*) AS High_Value_Sales
FROM Sales s
JOIN Employee e ON s.employee_id = e.employee_id
WHERE s.total_amount > 1000
GROUP BY e.name
ORDER BY High_Value_Sales DESC;
GO

-- Query 5: Retrieve medicines with stock less than average stock quantity
-- Purpose: Identify understocked medicines for reordering
SELECT 
    m.name,
    m.brand,
    b.batch_no,
    b.stock_qty
FROM Batch b
JOIN Medicine m ON b.medicine_id = m.medicine_id
WHERE b.stock_qty < (SELECT AVG(stock_qty) FROM Batch)
    AND b.expiry_date > GETDATE()
ORDER BY b.stock_qty ASC;
GO

-- Query 6: Group by supplier and find average purchase amount
-- Purpose: Supplier relationship and procurement value analysis
SELECT 
    s.supplier_name,
    COUNT(p.purchase_id) AS Total_Purchases,
    AVG(p.total_amount) AS Average_Purchase_Amount,
    SUM(p.total_amount) AS Total_Amount_Paid
FROM Supplier s
JOIN Purchase p ON s.supplier_id = p.supplier_id
GROUP BY s.supplier_name
HAVING COUNT(p.purchase_id) >= 2
ORDER BY Total_Amount_Paid DESC;
GO


-- ==============================================================================
-- CATEGORY 6: ADVANCED QUERIES (BONUS)
-- ==============================================================================

-- Query 1: Revenue by Category with Percentage
-- Purpose: Business intelligence - category contribution analysis
WITH CategoryRevenue AS (
    SELECT 
        c.category_name,
        SUM(si.quantity * si.selling_price) AS Category_Revenue
    FROM Sales_Items si
    JOIN Batch b ON si.batch_id = b.batch_id
    JOIN Medicine m ON b.medicine_id = m.medicine_id
    JOIN Category c ON m.category_id = c.category_id
    GROUP BY c.category_name
)
SELECT 
    category_name,
    Category_Revenue,
    CAST(Category_Revenue * 100.0 / (SELECT SUM(Category_Revenue) FROM CategoryRevenue) AS DECIMAL(5,2)) AS Percentage_of_Total
FROM CategoryRevenue
ORDER BY Category_Revenue DESC;
GO

-- Query 2: Monthly Sales Trend
-- Purpose: Time-series analysis for business trends
SELECT 
    YEAR(sales_date) AS Year,
    MONTH(sales_date) AS Month,
    DATENAME(MONTH, sales_date) AS Month_Name,
    COUNT(*) AS Total_Orders,
    SUM(total_amount) AS Total_Revenue,
    AVG(total_amount) AS Average_Order_Value
FROM Sales
GROUP BY YEAR(sales_date), MONTH(sales_date), DATENAME(MONTH, sales_date)
ORDER BY Year DESC, Month DESC;
GO

-- Query 3: Top 5 Best-Selling Medicines
-- Purpose: Most popular medicines by sales volume
SELECT TOP 5
    m.name AS Medicine_Name,
    m.brand,
    c.category_name,
    SUM(si.quantity) AS Total_Units_Sold,
    SUM(si.quantity * si.selling_price) AS Total_Revenue
FROM Sales_Items si
JOIN Batch b ON si.batch_id = b.batch_id
JOIN Medicine m ON b.medicine_id = m.medicine_id
JOIN Category c ON m.category_id = c.category_id
GROUP BY m.name, m.brand, c.category_name
ORDER BY Total_Units_Sold DESC;
GO

-- Query 4: Customer Lifetime Value
-- Purpose: VIP customer identification for loyalty programs
SELECT TOP 10
    c.name AS Customer_Name,
    c.phone,
    COUNT(s.sales_id) AS Total_Orders,
    SUM(s.total_amount) AS Total_Spent,
    AVG(s.total_amount) AS Average_Order_Value,
    MAX(s.sales_date) AS Last_Purchase_Date
FROM Customer c
JOIN Sales s ON c.customer_id = s.customer_id
GROUP BY c.name, c.phone
ORDER BY Total_Spent DESC;
GO


-- ==============================================================================
-- QUERY SUMMARY
-- ==============================================================================
-- Total Queries: 34
-- 
-- Category 1: Basic WHERE Queries       - 6 queries
-- Category 2: JOIN Operations           - 6 queries
-- Category 3: Set Operations            - 6 queries
-- Category 4: Aggregate Functions       - 6 queries
-- Category 5: GROUP BY/HAVING          - 6 queries
-- Category 6: Advanced Queries          - 4 queries
-- ==============================================================================
-- All queries tested on Ph_Store database (SQL Server)
-- Author: Pharmaceutical Store Management System
-- Date: 2024
-- ==============================================================================
