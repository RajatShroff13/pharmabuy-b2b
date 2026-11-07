USE Ph_Store;
GO

-- Restore original admin/staff logins
-- Passwords are plain text as per the original schema (hash them in production)

-- Only insert if username doesn't already exist
IF NOT EXISTS (SELECT 1 FROM User_Login WHERE username = 'admin')
    INSERT INTO User_Login (username, password, role) VALUES ('admin', 'admin123', 'ADMIN');

IF NOT EXISTS (SELECT 1 FROM User_Login WHERE username = 'manager1')
    INSERT INTO User_Login (username, password, role) VALUES ('manager1', 'manager123', 'MANAGER');

IF NOT EXISTS (SELECT 1 FROM User_Login WHERE username = 'pharmacist1')
    INSERT INTO User_Login (username, password, role) VALUES ('pharmacist1', 'pharma123', 'PHARMACIST');

IF NOT EXISTS (SELECT 1 FROM User_Login WHERE username = 'cashier1')
    INSERT INTO User_Login (username, password, role) VALUES ('cashier1', 'cash123', 'CASHIER');
GO

-- Verify
SELECT user_id, username, role FROM User_Login 
WHERE username IN ('admin', 'manager1', 'pharmacist1', 'cashier1');
GO
