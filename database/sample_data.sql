
USE Ph_Store;
GO

-- ============================================================
-- CLEAR EXISTING DATA (in dependency order)
-- ============================================================
DELETE FROM Prescription_Items;
DELETE FROM Prescription;
DELETE FROM Returns;
DELETE FROM Payment;
DELETE FROM Sales_Items;
DELETE FROM Sales;
DELETE FROM Stock_Log;
DELETE FROM Purchase_Items;
DELETE FROM Purchase;
DELETE FROM Batch;
DELETE FROM Medicine;
DELETE FROM Category;
DELETE FROM Customer;
DELETE FROM Employee;
DELETE FROM Supplier;
DELETE FROM User_Login;
GO

-- ============================================================
-- 1. USER_LOGIN (8 users)
-- ============================================================
INSERT INTO User_Login (username, password, role) VALUES
('admin',        'admin123',    'ADMIN'),
('manager1',     'manager123',  'MANAGER'),
('manager2',     'manager123',  'MANAGER'),
('pharmacist1',  'pharma123',   'PHARMACIST'),
('pharmacist2',  'pharma123',   'PHARMACIST'),
('pharmacist3',  'pharma123',   'PHARMACIST'),
('cashier1',     'cash123',     'CASHIER'),
('cashier2',     'cash123',     'CASHIER');
GO

-- ============================================================
-- 2. CATEGORY (10 categories)
-- ============================================================
INSERT INTO Category (category_name) VALUES
('Antibiotics'),
('Pain Relief'),
('Vitamins & Supplements'),
('Cold & Flu'),
('Digestive Health'),
('Diabetes Care'),
('Heart & Blood Pressure'),
('Skin Care'),
('Eye & Ear Care'),
('Respiratory');
GO

-- ============================================================
-- 3. SUPPLIER (8 suppliers)
-- ============================================================
INSERT INTO Supplier (supplier_name, phone, email, address) VALUES
('MedSupply Co.',           '9876543210', 'contact@medsupply.com',     '123 Medical Street, Mumbai'),
('PharmaDirect Ltd.',       '9876543211', 'sales@pharmadirect.com',    '456 Health Avenue, Delhi'),
('HealthDistributors',      '9876543212', 'info@healthdist.com',       '789 Wellness Road, Bangalore'),
('Cipla Distributors',      '9876543213', 'orders@cipladist.com',      '12 Pharma Lane, Pune'),
('Sun Pharma Dealers',      '9876543214', 'supply@sundealers.com',     '34 Sun Road, Hyderabad'),
('Mankind Wholesale',       '9876543215', 'bulk@mankindwho.com',       '56 Mankind Nagar, Chennai'),
('Dr. Reddy Suppliers',     '9876543216', 'drreddy@suppliers.com',     '78 Reddy Complex, Kolkata'),
('Himalaya Medical Store',  '9876543217', 'hms@himalayamed.com',       '90 Himalaya Block, Nashik');
GO

-- ============================================================
-- 4. EMPLOYEE (8 employees)
-- ============================================================
INSERT INTO Employee (name, role, phone, salary) VALUES
('Rajesh Kumar',    'MANAGER',    '9876540001', 55000.00),
('Sunita Sharma',   'MANAGER',    '9876540002', 52000.00),
('Priya Patel',     'PHARMACIST', '9876540003', 32000.00),
('Amit Singh',      'PHARMACIST', '9876540004', 30000.00),
('Neha Verma',      'PHARMACIST', '9876540005', 31000.00),
('Rohit Desai',     'CASHIER',    '9876540006', 22000.00),
('Pooja Mehta',     'CASHIER',    '9876540007', 21000.00),
('Suresh Yadav',    'CASHIER',    '9876540008', 20000.00);
GO

-- ============================================================
-- 5. CUSTOMER (15 customers)
-- ============================================================
INSERT INTO Customer (name, phone, address) VALUES
('Ramesh Medical Store',      '9800000001', 'Shop 1, MG Road, Nashik'),
('Sneha Pharma',              '9800000002', 'Plot 5, College Road, Nashik'),
('Vikram Drug House',         '9800000003', 'Opp Bus Stand, Nashik'),
('City Chemist',              '9800000004', 'Main Bazar, Nashik'),
('Ganesh Medical',            '9800000005', 'Panchavati, Nashik'),
('Laxmi Drug Store',          '9800000006', 'Dwarka Circle, Nashik'),
('Shivaji Medical',           '9800000007', 'Indira Nagar, Nashik'),
('Healthy Life Pharmacy',     '9800000008', 'Cidco, Nashik'),
('Amrut Medical Store',       '9800000009', 'Satpur, Nashik'),
('Om Sai Pharma',             '9800000010', 'Ambad, Nashik'),
('New Life Medical',          '9800000011', 'Gangapur Road, Nashik'),
('Shree Medical Center',      '9800000012', 'Pathardi Phata, Nashik'),
('Unique Drug Store',         '9800000013', 'Mahatma Nagar, Nashik'),
('Arogya Medical',            '9800000014', 'Tidke Colony, Nashik'),
('Swasth Pharmacy',           '9800000015', 'Sharanpur Road, Nashik');
GO

-- ============================================================
-- 6. MEDICINE (40 medicines)
-- ============================================================
INSERT INTO Medicine (name, brand, category_id, description, gst_percent, mrp) VALUES
-- Antibiotics (cat 1)
('Amoxicillin 500mg',       'Cipla',        1, 'Broad spectrum antibiotic for infections',         12.00,  85.00),
('Azithromycin 250mg',      'Cipla',        1, 'Antibiotic for respiratory infections',            12.00, 110.00),
('Ciprofloxacin 500mg',     'Sun Pharma',   1, 'Antibiotic for urinary tract infections',          12.00,  95.00),
('Doxycycline 100mg',       'Mankind',      1, 'Antibiotic for skin and respiratory infections',   12.00,  75.00),
('Metronidazole 400mg',     'Abbott',       1, 'Antibiotic and antiprotozoal medication',          12.00,  55.00),

-- Pain Relief (cat 2)
('Paracetamol 650mg',       'GSK',          2, 'Fever and mild to moderate pain relief',            5.00,  25.00),
('Ibuprofen 400mg',         'Cipla',        2, 'Anti-inflammatory and pain relief',                 5.00,  40.00),
('Diclofenac 50mg',         'Novartis',     2, 'Anti-inflammatory for joint and muscle pain',       5.00,  55.00),
('Aceclofenac 100mg',       'Sun Pharma',   2, 'Pain relief for arthritis and dental pain',         5.00,  65.00),
('Tramadol 50mg',           'Mankind',      2, 'Moderate to severe pain relief',                   12.00,  90.00),

-- Vitamins (cat 3)
('Vitamin C 500mg',         'Himalaya',     3, 'Immunity booster and antioxidant supplement',       5.00, 120.00),
('Vitamin D3 1000IU',       'Abbott',       3, 'Bone health and immunity support',                  5.00, 180.00),
('Vitamin B12 500mcg',      'Cipla',        3, 'Nerve health and energy supplement',                5.00, 150.00),
('Multivitamin Tablet',     'Pfizer',       3, 'Daily multivitamin and mineral supplement',         5.00,  95.00),
('Calcium + D3 500mg',      'GSK',          3, 'Calcium and Vitamin D3 combination supplement',     5.00, 210.00),

-- Cold & Flu (cat 4)
('Cetirizine 10mg',         'Mankind',      4, 'Antihistamine for cold and allergy relief',        12.00,  45.00),
('Levocetirizine 5mg',      'Sun Pharma',   4, 'Second generation antihistamine',                  12.00,  55.00),
('Phenylephrine 10mg',      'Cipla',        4, 'Nasal decongestant for cold',                      12.00,  35.00),
('Bromhexine 8mg',          'Boehringer',   4, 'Expectorant for chesty cough',                     12.00,  48.00),
('Montelukast 10mg',        'MSD',          4, 'Allergy and asthma symptom relief',                12.00, 135.00),

-- Digestive (cat 5)
('Omeprazole 20mg',         'Sun Pharma',   5, 'Proton pump inhibitor for acidity',                12.00,  60.00),
('Pantoprazole 40mg',       'Cipla',        5, 'Acid reflux and peptic ulcer treatment',           12.00,  72.00),
('Domperidone 10mg',        'Janssen',      5, 'Nausea, vomiting and gastric motility',            12.00,  42.00),
('Ranitidine 150mg',        'GSK',          5, 'H2 blocker for acidity and ulcers',                12.00,  38.00),
('ORS Sachet',              'Electral',     5, 'Oral rehydration salts for dehydration',            5.00,  18.00),

-- Diabetes (cat 6)
('Metformin 500mg',         'Cipla',        6, 'First line diabetes management tablet',             5.00,  95.00),
('Glimepiride 1mg',         'Sun Pharma',   6, 'Sulfonylurea for type 2 diabetes',                  5.00, 115.00),
('Januvia 100mg',           'MSD',          6, 'DPP-4 inhibitor for type 2 diabetes',              12.00, 320.00),
('Insulin Glargine',        'Sanofi',       6, 'Long acting insulin for diabetes',                 12.00, 850.00),
('Glucometer Strips',       'Accu-Chek',    6, 'Blood glucose test strips (25 count)',              5.00, 380.00),

-- Heart (cat 7)
('Amlodipine 5mg',          'Cipla',        7, 'Calcium channel blocker for hypertension',         12.00,  85.00),
('Atenolol 50mg',           'Sun Pharma',   7, 'Beta blocker for high blood pressure',             12.00,  65.00),
('Atorvastatin 10mg',       'Pfizer',       7, 'Statin for cholesterol management',                12.00, 145.00),
('Clopidogrel 75mg',        'Sanofi',       7, 'Antiplatelet for heart attack prevention',         12.00, 175.00),
('Losartan 50mg',           'Mankind',      7, 'ARB for hypertension and heart failure',           12.00,  95.00),

-- Skin Care (cat 8)
('Betamethasone Cream',     'GSK',          8, 'Topical steroid for skin inflammation',            12.00,  85.00),
('Clotrimazole Cream',      'Bayer',        8, 'Antifungal cream for skin infections',             12.00,  75.00),

-- Eye & Ear (cat 9)
('Ciprofloxacin Eye Drops', 'Sun Pharma',   9, 'Antibiotic eye drops for infections',              12.00,  65.00),
('Otrivin Nasal Spray',     'Novartis',     9, 'Nasal decongestant spray',                         12.00,  95.00),

-- Respiratory (cat 10)
('Salbutamol Inhaler',      'GSK',         10, 'Bronchodilator for asthma relief',                 12.00, 185.00),
('Budesonide Inhaler',      'AstraZeneca', 10, 'Corticosteroid inhaler for asthma control',        12.00, 420.00);
GO

-- ============================================================
-- 7. BATCH (40+ batches with stock)
-- ============================================================
INSERT INTO Batch (medicine_id, batch_no, manufacture_date, expiry_date, cost_price, selling_price, stock_qty, rack_location) VALUES
(1,  'AMX2401', '2024-01-01', '2026-12-31',  60.00,  75.00, 200, 'A-01'),
(2,  'AZT2401', '2024-01-01', '2026-12-31',  80.00,  98.00, 150, 'A-02'),
(3,  'CIP2401', '2024-02-01', '2026-11-30',  68.00,  84.00, 180, 'A-03'),
(4,  'DOX2401', '2024-02-01', '2026-10-31',  52.00,  66.00, 120, 'A-04'),
(5,  'MET2401', '2024-03-01', '2026-09-30',  38.00,  48.00, 160, 'A-05'),
(6,  'PCM2401', '2024-01-01', '2026-12-31',  15.00,  22.00, 500, 'B-01'),
(7,  'IBU2401', '2024-01-01', '2026-12-31',  28.00,  35.00, 300, 'B-02'),
(8,  'DCL2401', '2024-02-01', '2026-11-30',  38.00,  48.00, 250, 'B-03'),
(9,  'ACL2401', '2024-02-01', '2026-10-31',  46.00,  58.00, 220, 'B-04'),
(10, 'TRM2401', '2024-03-01', '2026-09-30',  65.00,  80.00,  90, 'B-05'),
(11, 'VTC2401', '2024-01-01', '2026-12-31',  85.00, 105.00, 180, 'C-01'),
(12, 'VTD2401', '2024-01-01', '2026-12-31', 130.00, 160.00, 140, 'C-02'),
(13, 'VTB2401', '2024-02-01', '2026-11-30', 108.00, 135.00, 100, 'C-03'),
(14, 'MVT2401', '2024-02-01', '2026-10-31',  68.00,  85.00, 200, 'C-04'),
(15, 'CAD2401', '2024-03-01', '2026-09-30', 150.00, 188.00, 120, 'C-05'),
(16, 'CTZ2401', '2024-01-01', '2026-12-31',  30.00,  40.00, 280, 'D-01'),
(17, 'LCT2401', '2024-01-01', '2026-12-31',  38.00,  48.00, 240, 'D-02'),
(18, 'PHE2401', '2024-02-01', '2026-11-30',  24.00,  31.00, 150, 'D-03'),
(19, 'BRX2401', '2024-02-01', '2026-10-31',  33.00,  42.00, 130, 'D-04'),
(20, 'MON2401', '2024-03-01', '2026-09-30',  95.00, 120.00, 100, 'D-05'),
(21, 'OMP2401', '2024-01-01', '2026-12-31',  42.00,  54.00, 220, 'E-01'),
(22, 'PNT2401', '2024-01-01', '2026-12-31',  50.00,  64.00, 190, 'E-02'),
(23, 'DMP2401', '2024-02-01', '2026-11-30',  28.00,  37.00, 160, 'E-03'),
(24, 'RNT2401', '2024-02-01', '2026-10-31',  25.00,  34.00, 140, 'E-04'),
(25, 'ORS2401', '2024-03-01', '2026-09-30',  10.00,  15.00, 400, 'E-05'),
(26, 'MFM2401', '2024-01-01', '2026-12-31',  68.00,  84.00, 260, 'F-01'),
(27, 'GLM2401', '2024-01-01', '2026-12-31',  82.00, 102.00, 180, 'F-02'),
(28, 'JAN2401', '2024-02-01', '2026-11-30', 230.00, 288.00,  80, 'F-03'),
(29, 'INS2401', '2024-02-01', '2026-10-31', 610.00, 762.00,  50, 'F-04'),
(30, 'GLS2401', '2024-03-01', '2026-09-30', 270.00, 338.00,  90, 'F-05'),
(31, 'AML2401', '2024-01-01', '2026-12-31',  60.00,  76.00, 200, 'G-01'),
(32, 'ATN2401', '2024-01-01', '2026-12-31',  46.00,  58.00, 170, 'G-02'),
(33, 'ATV2401', '2024-02-01', '2026-11-30', 104.00, 130.00, 130, 'G-03'),
(34, 'CLO2401', '2024-02-01', '2026-10-31', 125.00, 156.00, 110, 'G-04'),
(35, 'LST2401', '2024-03-01', '2026-09-30',  68.00,  85.00, 150, 'G-05'),
(36, 'BTM2401', '2024-01-01', '2026-12-31',  60.00,  76.00, 120, 'H-01'),
(37, 'CLT2401', '2024-01-01', '2026-12-31',  52.00,  66.00, 100, 'H-02'),
(38, 'CEY2401', '2024-02-01', '2026-11-30',  46.00,  58.00,  90, 'H-03'),
(39, 'OTR2401', '2024-02-01', '2026-10-31',  68.00,  85.00,  80, 'H-04'),
(40, 'SLB2401', '2024-03-01', '2026-09-30', 132.00, 165.00,  75, 'I-01'),
(41, 'BUD2401', '2024-03-01', '2026-09-30', 300.00, 375.00,  60, 'I-02');
GO

-- ============================================================
-- 8. PURCHASE (10 purchases)
-- ============================================================
INSERT INTO Purchase (supplier_id, purchase_date, total_amount) VALUES
(1, '2024-01-05',  45000.00),
(2, '2024-01-12',  38000.00),
(3, '2024-02-03',  52000.00),
(4, '2024-02-18',  29000.00),
(5, '2024-03-01',  67000.00),
(1, '2024-03-15',  41000.00),
(6, '2024-04-02',  33000.00),
(7, '2024-04-20',  58000.00),
(8, '2024-05-05',  72000.00),
(2, '2024-05-22',  48000.00);
GO

-- ============================================================
-- 9. PURCHASE_ITEMS (20 purchase items)
-- ============================================================
INSERT INTO Purchase_Items (purchase_id, batch_id, quantity, cost_price) VALUES
(1,  1, 100, 60.00),
(1,  2,  80, 80.00),
(2,  6, 200, 15.00),
(2,  7, 150, 28.00),
(3, 11, 100, 85.00),
(3, 12,  80,130.00),
(4, 16, 150, 30.00),
(4, 17, 120, 38.00),
(5, 21, 120, 42.00),
(5, 26, 150, 68.00),
(6,  3, 100, 68.00),
(6,  8, 130, 38.00),
(7, 31, 110, 60.00),
(7, 32,  90, 46.00),
(8, 28,  50,230.00),
(8, 29,  30,610.00),
(9, 40,  50,132.00),
(9, 41,  40,300.00),
(10, 33,  70,104.00),
(10, 34,  60,125.00);
GO

-- ============================================================
-- 10. STOCK_LOG (purchase entries)
-- ============================================================
INSERT INTO Stock_Log (batch_id, change_type, qty, date) VALUES
(1,  'PURCHASE', 100, '2024-01-05'),
(2,  'PURCHASE',  80, '2024-01-05'),
(6,  'PURCHASE', 200, '2024-01-12'),
(7,  'PURCHASE', 150, '2024-01-12'),
(11, 'PURCHASE', 100, '2024-02-03'),
(12, 'PURCHASE',  80, '2024-02-03'),
(16, 'PURCHASE', 150, '2024-02-18'),
(17, 'PURCHASE', 120, '2024-02-18'),
(21, 'PURCHASE', 120, '2024-03-01'),
(26, 'PURCHASE', 150, '2024-03-01');
GO

-- ============================================================
-- 11. SALES (20 sales orders)
-- ============================================================
INSERT INTO Sales (customer_id, employee_id, sales_date, total_amount) VALUES
(1,  1, '2024-02-10',  1850.00),
(2,  3, '2024-02-14',  2340.00),
(3,  4, '2024-02-20',   980.00),
(4,  3, '2024-03-02',  3200.00),
(5,  5, '2024-03-10',  1450.00),
(6,  1, '2024-03-18',  2750.00),
(7,  3, '2024-03-25',   870.00),
(8,  4, '2024-04-05',  4100.00),
(9,  5, '2024-04-12',  1560.00),
(10, 3, '2024-04-20',  2200.00),
(11, 1, '2024-05-01',  3400.00),
(12, 4, '2024-05-08',  1100.00),
(13, 5, '2024-05-15',  2600.00),
(14, 3, '2024-05-22',  1750.00),
(15, 1, '2024-06-01',  3100.00),
(1,  4, '2024-06-10',  2400.00),
(2,  5, '2024-06-18',  1900.00),
(3,  3, '2024-06-25',  2800.00),
(4,  1, '2024-07-05',  1650.00),
(5,  4, '2024-07-12',  3200.00);
GO

-- ============================================================
-- 12. SALES_ITEMS (40 sales line items)
-- ============================================================
INSERT INTO Sales_Items (sales_id, batch_id, quantity, selling_price) VALUES
(1,  1,  5, 75.00),
(1,  6, 20, 22.00),
(1, 11,  8,105.00),
(2,  2,  6, 98.00),
(2, 16, 15, 40.00),
(2, 21, 10, 54.00),
(3,  7, 10, 35.00),
(3, 22,  8, 64.00),
(4, 28,  3,288.00),
(4, 26, 10, 84.00),
(4, 31,  8, 76.00),
(5, 12,  4,160.00),
(5, 13,  5,135.00),
(6, 29,  1,762.00),
(6, 33,  5,130.00),
(6, 14, 10, 85.00),
(7,  8,  5, 48.00),
(7, 23,  8, 37.00),
(8, 30,  5,338.00),
(8, 40,  3,165.00),
(8, 41,  2,375.00),
(9, 16, 12, 40.00),
(9, 17, 10, 48.00),
(10, 6, 30, 22.00),
(10, 7, 15, 35.00),
(11, 34, 5,156.00),
(11, 35, 8, 85.00),
(12, 18,10, 31.00),
(12, 19, 8, 42.00),
(13, 32, 7, 58.00),
(13, 33, 5,130.00),
(14, 24,12, 34.00),
(14, 25,20, 15.00),
(15, 3,  8, 84.00),
(15, 4,  6, 66.00),
(16, 9,  7, 58.00),
(16, 10, 4, 80.00),
(17, 5,  6, 48.00),
(18, 20, 5,120.00),
(20, 27, 8,102.00);
GO

-- ============================================================
-- 13. PAYMENT (20 payments)
-- ============================================================
INSERT INTO Payment (sales_id, payment_mode, amount) VALUES
(1,  'CASH',        1850.00),
(2,  'UPI',         2340.00),
(3,  'CASH',         980.00),
(4,  'NET_BANKING', 3200.00),
(5,  'UPI',         1450.00),
(6,  'CARD',        2750.00),
(7,  'CASH',         870.00),
(8,  'CHEQUE',      4100.00),
(9,  'UPI',         1560.00),
(10, 'CASH',        2200.00),
(11, 'NET_BANKING', 3400.00),
(12, 'UPI',         1100.00),
(13, 'CARD',        2600.00),
(14, 'CASH',        1750.00),
(15, 'UPI',         3100.00),
(16, 'CARD',        2400.00),
(17, 'CASH',        1900.00),
(18, 'NET_BANKING', 2800.00),
(19, 'UPI',         1650.00),
(20, 'CARD',        3200.00);
GO

-- ============================================================
-- 14. STOCK_LOG (sale entries)
-- ============================================================
INSERT INTO Stock_Log (batch_id, change_type, qty, date) VALUES
(1,  'SALE',  -5,  '2024-02-10'),
(6,  'SALE', -20,  '2024-02-10'),
(11, 'SALE',  -8,  '2024-02-10'),
(2,  'SALE',  -6,  '2024-02-14'),
(16, 'SALE', -15,  '2024-02-14'),
(21, 'SALE', -10,  '2024-02-14'),
(7,  'SALE', -10,  '2024-02-20'),
(22, 'SALE',  -8,  '2024-02-20'),
(28, 'SALE',  -3,  '2024-03-02'),
(26, 'SALE', -10,  '2024-03-02'),
(31, 'SALE',  -8,  '2024-03-02'),
(12, 'SALE',  -4,  '2024-03-10'),
(13, 'SALE',  -5,  '2024-03-10'),
(29, 'SALE',  -1,  '2024-03-18'),
(33, 'SALE',  -5,  '2024-03-18'),
(14, 'SALE', -10,  '2024-03-18'),
(8,  'SALE',  -5,  '2024-03-25'),
(23, 'SALE',  -8,  '2024-03-25'),
(30, 'SALE',  -5,  '2024-04-05'),
(40, 'SALE',  -3,  '2024-04-05');
GO

-- ============================================================
-- 15. RETURNS (8 returns)
-- ============================================================
INSERT INTO Returns (sales_id, batch_id, quantity, reason, date) VALUES
(1,  6,  2, 'Customer ordered excess quantity',        '2024-02-12'),
(3,  7,  1, 'Product packaging damaged',               '2024-02-22'),
(5, 12,  1, 'Wrong medicine dispensed',                '2024-03-12'),
(8, 30,  1, 'Customer found better price elsewhere',   '2024-04-07'),
(10, 6,  5, 'Bulk order partially returned',           '2024-04-22'),
(12,18,  2, 'Near expiry batch concern',               '2024-05-10'),
(15, 3,  1, 'Damaged outer box',                       '2024-06-03'),
(18,20,  1, 'Customer changed prescription',           '2024-06-27');
GO

-- ============================================================
-- 16. PRESCRIPTION (10 prescriptions)
-- ============================================================
INSERT INTO Prescription (doctor_name, customer_id, date) VALUES
('Dr. Anil Mehta',      1, '2024-02-10'),
('Dr. Sunita Rao',      2, '2024-02-14'),
('Dr. Vikram Joshi',    3, '2024-03-02'),
('Dr. Priya Nair',      4, '2024-03-18'),
('Dr. Rahul Gupta',     5, '2024-04-05'),
('Dr. Kavita Sharma',   6, '2024-04-20'),
('Dr. Suresh Patil',    7, '2024-05-01'),
('Dr. Meena Desai',     8, '2024-05-15'),
('Dr. Anil Mehta',      9, '2024-06-01'),
('Dr. Sunita Rao',     10, '2024-06-18');
GO

-- ============================================================
-- 17. PRESCRIPTION_ITEMS (20 prescription items)
-- ============================================================
INSERT INTO Prescription_Items (prescription_id, medicine_id, dosage) VALUES
(1,  1, '1 tablet twice daily for 7 days'),
(1,  6, '1 tablet as needed for fever'),
(2,  2, '1 tablet once daily for 5 days'),
(2, 16, '1 tablet at night for allergy'),
(3, 26, '1 tablet twice daily with meals'),
(3, 21, '1 tablet before breakfast'),
(4, 31, '1 tablet once daily in morning'),
(4, 33, '1 tablet at bedtime'),
(5, 11, '1 tablet daily with vitamin C'),
(5, 12, '1 tablet daily with calcium'),
(6, 29, '10 units subcutaneous injection daily'),
(6, 27, '1 tablet daily with breakfast'),
(7, 40, '2 puffs when needed for breathing'),
(7, 20, '1 tablet daily in evening'),
(8, 32, '1 tablet daily in morning'),
(8,  7, '1 tablet three times daily after meals'),
(9,  3, '1 tablet twice daily for 7 days'),
(9, 22, '1 tablet before dinner'),
(10, 13, '1 tablet daily for 30 days'),
(10, 14, '1 tablet daily with breakfast');
GO

-- ============================================================
-- VERIFY DATA
-- ============================================================
SELECT 'User_Login'         AS TableName, COUNT(*) AS Rows FROM User_Login         UNION ALL
SELECT 'Category',                         COUNT(*)        FROM Category            UNION ALL
SELECT 'Supplier',                         COUNT(*)        FROM Supplier            UNION ALL
SELECT 'Employee',                         COUNT(*)        FROM Employee            UNION ALL
SELECT 'Customer',                         COUNT(*)        FROM Customer            UNION ALL
SELECT 'Medicine',                         COUNT(*)        FROM Medicine            UNION ALL
SELECT 'Batch',                            COUNT(*)        FROM Batch               UNION ALL
SELECT 'Purchase',                         COUNT(*)        FROM Purchase            UNION ALL
SELECT 'Purchase_Items',                   COUNT(*)        FROM Purchase_Items      UNION ALL
SELECT 'Stock_Log',                        COUNT(*)        FROM Stock_Log           UNION ALL
SELECT 'Sales',                            COUNT(*)        FROM Sales               UNION ALL
SELECT 'Sales_Items',                      COUNT(*)        FROM Sales_Items         UNION ALL
SELECT 'Payment',                          COUNT(*)        FROM Payment             UNION ALL
SELECT 'Returns',                          COUNT(*)        FROM Returns             UNION ALL
SELECT 'Prescription',                     COUNT(*)        FROM Prescription        UNION ALL
SELECT 'Prescription_Items',               COUNT(*)        FROM Prescription_Items;
GO

-- ============================================================
-- ALL DONE! Login with:
-- Username: admin    Password: admin123
-- Username: manager1 Password: manager123
-- ============================================================
