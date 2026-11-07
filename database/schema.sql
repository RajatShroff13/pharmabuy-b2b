
-- Pharmaceutical Store Management System - Database Schema

create database Ph_Store;
use Ph_Store;

-- Drop existing tables if they exist (in reverse order of dependencies)
IF OBJECT_ID('Prescription_Items', 'U') IS NOT NULL DROP TABLE Prescription_Items;
IF OBJECT_ID('Prescription', 'U') IS NOT NULL DROP TABLE Prescription;
IF OBJECT_ID('Returns', 'U') IS NOT NULL DROP TABLE Returns;
IF OBJECT_ID('Payment', 'U') IS NOT NULL DROP TABLE Payment;
IF OBJECT_ID('Sales_Items', 'U') IS NOT NULL DROP TABLE Sales_Items;
IF OBJECT_ID('Sales', 'U') IS NOT NULL DROP TABLE Sales;
IF OBJECT_ID('Purchase_Items', 'U') IS NOT NULL DROP TABLE Purchase_Items;
IF OBJECT_ID('Purchase', 'U') IS NOT NULL DROP TABLE Purchase;
IF OBJECT_ID('Stock_Log', 'U') IS NOT NULL DROP TABLE Stock_Log;
IF OBJECT_ID('Batch', 'U') IS NOT NULL DROP TABLE Batch;
IF OBJECT_ID('Medicine', 'U') IS NOT NULL DROP TABLE Medicine;
IF OBJECT_ID('Category', 'U') IS NOT NULL DROP TABLE Category;
IF OBJECT_ID('Customer', 'U') IS NOT NULL DROP TABLE Customer;
IF OBJECT_ID('Employee', 'U') IS NOT NULL DROP TABLE Employee;
IF OBJECT_ID('Supplier', 'U') IS NOT NULL DROP TABLE Supplier;
IF OBJECT_ID('User_Login', 'U') IS NOT NULL DROP TABLE User_Login;
GO


-- 1. CATEGORY Table

CREATE TABLE Category (
    category_id INT PRIMARY KEY IDENTITY(1,1),
    category_name VARCHAR(100) NOT NULL UNIQUE
);
GO


-- 2. MEDICINE Table

CREATE TABLE Medicine (
    medicine_id INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(200) NOT NULL,
    brand VARCHAR(100),
    category_id INT NOT NULL,
    description VARCHAR(1000),
    gst_percent DECIMAL(5,2) DEFAULT 0.00,
    mrp DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (category_id) REFERENCES Category(category_id)
);
GO


-- 3. BATCH Table

CREATE TABLE Batch (
    batch_id INT PRIMARY KEY IDENTITY(1,1),
    medicine_id INT NOT NULL,
    batch_no VARCHAR(50) NOT NULL,
    manufacture_date DATE NOT NULL,
    expiry_date DATE NOT NULL,
    cost_price DECIMAL(10,2) NOT NULL,
    selling_price DECIMAL(10,2) NOT NULL,
    stock_qty INT NOT NULL DEFAULT 0,
    rack_location VARCHAR(50),
    FOREIGN KEY (medicine_id) REFERENCES Medicine(medicine_id),
    CONSTRAINT UQ_Batch UNIQUE (medicine_id, batch_no),
    CONSTRAINT CHK_Batch_Expiry CHECK (expiry_date > manufacture_date),
    CONSTRAINT CHK_Batch_Price CHECK (selling_price >= cost_price),
    CONSTRAINT CHK_Batch_Stock CHECK (stock_qty >= 0)
);
GO


-- 4. STOCK_LOG Table

CREATE TABLE Stock_Log (
    log_id INT PRIMARY KEY IDENTITY(1,1),
    batch_id INT NOT NULL,
    change_type VARCHAR(20) NOT NULL,
    qty INT NOT NULL,
    date DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (batch_id) REFERENCES Batch(batch_id),
    CONSTRAINT CHK_StockLog_Type CHECK (change_type IN ('PURCHASE', 'SALE', 'RETURN', 'ADJUSTMENT', 'DAMAGE'))
);
GO


-- 5. SUPPLIER Table

CREATE TABLE Supplier (
    supplier_id INT PRIMARY KEY IDENTITY(1,1),
    supplier_name VARCHAR(200) NOT NULL,
    phone VARCHAR(15) NOT NULL UNIQUE,
    email VARCHAR(100),
    address TEXT
);
GO


-- 6. PURCHASE Table

CREATE TABLE Purchase (
    purchase_id INT PRIMARY KEY IDENTITY(1,1),
    supplier_id INT NOT NULL,
    purchase_date DATE NOT NULL,
    total_amount DECIMAL(12,2) NOT NULL,
    FOREIGN KEY (supplier_id) REFERENCES Supplier(supplier_id),
    CONSTRAINT CHK_Purchase_Amount CHECK (total_amount >= 0)
);
GO


-- 7. PURCHASE_ITEMS Table

CREATE TABLE Purchase_Items (
    purchase_id INT NOT NULL,
    batch_id INT NOT NULL,
    quantity INT NOT NULL,
    cost_price DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (purchase_id, batch_id),
    FOREIGN KEY (purchase_id) REFERENCES Purchase(purchase_id),
    FOREIGN KEY (batch_id) REFERENCES Batch(batch_id),
    CONSTRAINT CHK_PurchaseItems_Qty CHECK (quantity > 0),
    CONSTRAINT CHK_PurchaseItems_Price CHECK (cost_price >= 0)
);
GO


-- 8. CUSTOMER Table

CREATE TABLE Customer (
    customer_id INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(200) NOT NULL,
    phone VARCHAR(15) NOT NULL UNIQUE,
    address TEXT,
    email VARCHAR(100) NULL,
    username VARCHAR(50) NULL   -- links a self-registered customer to User_Login
);
GO


-- 9. EMPLOYEE Table

CREATE TABLE Employee (
    employee_id INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(200) NOT NULL,
    role VARCHAR(50) NOT NULL,
    phone VARCHAR(15) NOT NULL UNIQUE,
    salary DECIMAL(10,2) NOT NULL,
    CONSTRAINT CHK_Employee_Salary CHECK (salary >= 0)
);
GO


-- 10. SALES Table

CREATE TABLE Sales (
    sales_id INT PRIMARY KEY IDENTITY(1,1),
    customer_id INT,
    employee_id INT NOT NULL,
    sales_date DATE NOT NULL,
    total_amount DECIMAL(12,2) NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES Customer(customer_id),
    FOREIGN KEY (employee_id) REFERENCES Employee(employee_id),
    CONSTRAINT CHK_Sales_Amount CHECK (total_amount >= 0)
);
GO


-- 11. SALES_ITEMS Table

CREATE TABLE Sales_Items (
    sales_id INT NOT NULL,
    batch_id INT NOT NULL,
    quantity INT NOT NULL,
    selling_price DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (sales_id, batch_id),
    FOREIGN KEY (sales_id) REFERENCES Sales(sales_id),
    FOREIGN KEY (batch_id) REFERENCES Batch(batch_id),
    CONSTRAINT CHK_SalesItems_Qty CHECK (quantity > 0),
    CONSTRAINT CHK_SalesItems_Price CHECK (selling_price >= 0)
);
GO


-- 12. PAYMENT Table

CREATE TABLE Payment (
    payment_id INT PRIMARY KEY IDENTITY(1,1),
    sales_id INT NOT NULL,
    payment_mode VARCHAR(20) NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    FOREIGN KEY (sales_id) REFERENCES Sales(sales_id),
    CONSTRAINT CHK_Payment_Mode CHECK (payment_mode IN ('CASH', 'CARD', 'UPI', 'NET_BANKING', 'CHEQUE')),
    CONSTRAINT CHK_Payment_Amount CHECK (amount > 0)
);
GO


-- 13. RETURNS Table

CREATE TABLE Returns (
    return_id INT PRIMARY KEY IDENTITY(1,1),
    sales_id INT NOT NULL,
    batch_id INT NOT NULL,
    quantity INT NOT NULL,
    reason TEXT,
    date DATE NOT NULL,
    FOREIGN KEY (sales_id) REFERENCES Sales(sales_id),
    FOREIGN KEY (batch_id) REFERENCES Batch(batch_id),
    CONSTRAINT CHK_Returns_Qty CHECK (quantity > 0)
);
GO


-- 14. PRESCRIPTION Table

CREATE TABLE Prescription (
    prescription_id INT PRIMARY KEY IDENTITY(1,1),
    doctor_name VARCHAR(200) NOT NULL,
    customer_id INT NOT NULL,
    date DATE NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES Customer(customer_id)
);
GO


-- 15. PRESCRIPTION_ITEMS Table

CREATE TABLE Prescription_Items (
    prescription_id INT NOT NULL,
    medicine_id INT NOT NULL,
    dosage VARCHAR(100) NOT NULL,
    PRIMARY KEY (prescription_id, medicine_id),
    FOREIGN KEY (prescription_id) REFERENCES Prescription(prescription_id),
    FOREIGN KEY (medicine_id) REFERENCES Medicine(medicine_id)
);
GO


-- 16. USER_LOGIN Table

CREATE TABLE User_Login (
    user_id INT PRIMARY KEY IDENTITY(1,1),
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL,
    CONSTRAINT CHK_UserLogin_Role CHECK (role IN ('ADMIN', 'MANAGER', 'PHARMACIST', 'CASHIER'))
);
GO


-- CREATE INDEXES FOR BETTER PERFORMANCE
-- ============================================================

-- Medicine indexes
CREATE INDEX idx_medicine_category ON Medicine(category_id);
CREATE INDEX idx_medicine_name ON Medicine(name);

-- Batch indexes
CREATE INDEX idx_batch_medicine ON Batch(medicine_id);
CREATE INDEX idx_batch_expiry ON Batch(expiry_date);

-- Purchase indexes
CREATE INDEX idx_purchase_supplier ON Purchase(supplier_id);
CREATE INDEX idx_purchase_date ON Purchase(purchase_date);

-- Sales indexes
CREATE INDEX idx_sales_customer ON Sales(customer_id);
CREATE INDEX idx_sales_employee ON Sales(employee_id);
CREATE INDEX idx_sales_date ON Sales(sales_date);

-- Stock_Log indexes
CREATE INDEX idx_stocklog_batch ON Stock_Log(batch_id);
CREATE INDEX idx_stocklog_date ON Stock_Log(date);

-- Prescription indexes
CREATE INDEX idx_prescription_customer ON Prescription(customer_id);
CREATE INDEX idx_prescription_date ON Prescription(date);
GO

-- ============================================================
-- SAMPLE DATA INSERTION
-- ============================================================

-- Insert sample categories
INSERT INTO Category (category_name) VALUES 
('Antibiotics'),
('Pain Relief'),
('Vitamins & Supplements'),
('Cold & Flu'),
('Digestive Health'),
('Diabetes Care');

-- Insert sample suppliers
INSERT INTO Supplier (supplier_name, phone, email, address) VALUES
('MedSupply Co.', '9876543210', 'contact@medsupply.com', '123 Medical Street, Mumbai'),
('PharmaDirect Ltd.', '9876543211', 'sales@pharmadirect.com', '456 Health Avenue, Delhi'),
('HealthDistributors', '9876543212', 'info@healthdist.com', '789 Wellness Road, Bangalore');

-- Insert sample employees
INSERT INTO Employee (name, role, phone, salary) VALUES
('Dr. Rajesh Kumar', 'MANAGER', '9876543220', 50000.00),
('Priya Sharma', 'PHARMACIST', '9876543221', 30000.00),
('Amit Patel', 'CASHIER', '9876543222', 20000.00);

-- Insert sample customers
INSERT INTO Customer (name, phone, address) VALUES
('Ramesh Verma', '9876543230', 'House 12, Sector 5, Nashik'),
('Sneha Desai', '9876543231', 'Flat 201, MG Road, Nashik'),
('Vikram Singh', '9876543232', 'Bungalow 45, College Road, Nashik');

-- Insert sample user logins (Note: In production, passwords should be hashed)
INSERT INTO User_Login (username, password, role) VALUES
('admin', 'admin123', 'ADMIN'),
('manager1', 'manager123', 'MANAGER'),
('pharmacist1', 'pharma123', 'PHARMACIST'),
('cashier1', 'cash123', 'CASHIER');
GO

ALTER TABLE Customer
ADD email VARCHAR(100);
ALTER TABLE Medicine 
ALTER COLUMN description VARCHAR(1000);
select * from Customer;
ALTER TABLE User_Login DROP CONSTRAINT CHK_UserLogin_Role;
ALTER TABLE User_Login ADD CONSTRAINT CHK_UserLogin_Role 
    CHECK (role IN ('ADMIN', 'MANAGER', 'PHARMACIST', 'CASHIER', 'CUSTOMER'));
ALTER TABLE Customer ADD username VARCHAR(50);