-- ============================================================
-- 001 - Customer account columns
-- ============================================================
-- The web application stores a customer's email and the linked login
-- username on the Customer row. Databases created from the original schema
-- do not have these columns; run this once against an existing database.
--
--   sqlcmd -S localhost\SQLEXPRESS -E -d Ph_Store -i database\migrations\001_customer_account_columns.sql
-- ============================================================

USE Ph_Store;
GO

IF COL_LENGTH('Customer', 'email') IS NULL
BEGIN
    ALTER TABLE Customer ADD email VARCHAR(100) NULL;
    PRINT 'Added Customer.email';
END
GO

IF COL_LENGTH('Customer', 'username') IS NULL
BEGIN
    ALTER TABLE Customer ADD username VARCHAR(50) NULL;
    PRINT 'Added Customer.username';
END
GO
