\connect west_branch

TRUNCATE TABLE DealProduct, Deal, ProductCategory, Category, Product, Customer RESTART IDENTITY CASCADE;

INSERT INTO Customer (Name) VALUES
	('West Customer 01'), ('West Customer 02'), ('West Customer 03'), ('West Customer 04'), ('West Customer 05'),
	('West Customer 06'), ('West Customer 07'), ('West Customer 08'), ('West Customer 09'), ('West Customer 10'),
	('West Customer 11'), ('West Customer 12'), ('West Customer 13'), ('West Customer 14'), ('West Customer 15'),
	('West Customer 16'), ('West Customer 17'), ('West Customer 18'), ('West Customer 19'), ('West Customer 20'),
	('West Customer 21'), ('West Customer 22'), ('West Customer 23'), ('West Customer 24'), ('West Customer 25');

INSERT INTO Product (Name, CatalogPrice) VALUES
	('West Product 01', 11.50), ('West Product 02', 13.00), ('West Product 03', 17.40), ('West Product 04', 18.90), ('West Product 05', 19.80),
	('West Product 06', 20.50), ('West Product 07', 22.30), ('West Product 08', 23.75), ('West Product 09', 24.90), ('West Product 10', 26.40),
	('West Product 11', 28.10), ('West Product 12', 29.95), ('West Product 13', 31.60), ('West Product 14', 33.20), ('West Product 15', 34.75),
	('West Product 16', 35.90), ('West Product 17', 37.40), ('West Product 18', 38.90), ('West Product 19', 40.25), ('West Product 20', 41.80),
	('West Product 21', 43.10), ('West Product 22', 44.60), ('West Product 23', 46.20), ('West Product 24', 47.75), ('West Product 25', 49.30);

INSERT INTO Category (Name) VALUES
	('West Category Home'),
	('West Category Office'),
	('West Category Sport'),
	('West Category Kids'),
	('West Category Garden'),
	('West Category Tech'),
	('West Category Beauty'),
	('West Category Outdoors');

INSERT INTO ProductCategory (ProductID, CategoryID) VALUES
	(1, 1),  (1, 4),
	(2, 2),  (2, 5),
	(3, 3),  (3, 6),
	(4, 4),  (4, 7),
	(5, 5),  (5, 8),
	(6, 6),  (6, 1),
	(7, 7),  (7, 2),
	(8, 8),  (8, 3),
	(9, 1),  (9, 5),
	(10, 2), (10, 6),
	(11, 3), (11, 7),
	(12, 4), (12, 8),
	(13, 5), (13, 1),
	(14, 6), (14, 2),
	(15, 7), (15, 3),
	(16, 8), (16, 4),
	(17, 1), (17, 6),
	(18, 2), (18, 7),
	(19, 3), (19, 8),
	(20, 4), (20, 1),
	(21, 5), (21, 2),
	(22, 6), (22, 3),
	(23, 7), (23, 4),
	(24, 8), (24, 5),
	(25, 1), (25, 7);

INSERT INTO Deal (CustomerID, TotalAmount, DealDate) VALUES
	(1, 0, '2024-01-02'), (2, 0, '2024-01-03'), (3, 0, '2024-01-04'), (4, 0, '2024-01-05'), (5, 0, '2024-01-06'),
	(6, 0, '2024-01-07'), (7, 0, '2024-01-08'), (8, 0, '2024-01-09'), (9, 0, '2024-01-10'), (10, 0, '2024-01-11'),
	(11, 0, '2024-01-12'), (12, 0, '2024-01-13'), (13, 0, '2024-01-14'), (14, 0, '2024-01-15'), (15, 0, '2024-01-16'),
	(16, 0, '2024-01-17'), (17, 0, '2024-01-18'), (18, 0, '2024-01-19'), (19, 0, '2024-01-20'), (20, 0, '2024-01-21'),
	(21, 0, '2024-01-22'), (22, 0, '2024-01-23'), (23, 0, '2024-01-24'), (24, 0, '2024-01-25'), (25, 0, '2024-01-26');

INSERT INTO DealProduct (DealID, ProductID, Quantity, Price) VALUES
	(1, 1, 2, 11.20),  (1, 6, 1, 20.10),
	(2, 2, 1, 13.00),  (2, 7, 3, 21.90),
	(3, 3, 1, 17.00),  (3, 8, 2, 23.00),
	(4, 4, 1, 18.90),  (4, 9, 2, 24.50),
	(5, 5, 2, 19.50),  (5, 10, 1, 26.00),
	(6, 6, 1, 20.50),  (6, 11, 2, 27.80),
	(7, 7, 2, 22.00),  (7, 12, 1, 29.50),
	(8, 8, 2, 23.40),  (8, 13, 1, 31.20),
	(9, 9, 1, 24.90),  (9, 14, 1, 32.80),
	(10, 10, 2, 26.10), (10, 15, 1, 34.50),
	(11, 11, 1, 28.10), (11, 16, 2, 35.40),
	(12, 12, 2, 29.60), (12, 17, 1, 37.00),
	(13, 13, 1, 31.20), (13, 18, 2, 38.40),
	(14, 14, 1, 33.00), (14, 19, 2, 39.90),
	(15, 15, 3, 34.00), (15, 20, 1, 41.40),
	(16, 16, 1, 35.90), (16, 21, 2, 42.70),
	(17, 17, 2, 37.10), (17, 22, 1, 44.20),
	(18, 18, 1, 38.90), (18, 23, 2, 45.70),
	(19, 19, 2, 40.00), (19, 24, 1, 47.20),
	(20, 20, 1, 41.60), (20, 25, 2, 48.90),
	(21, 3, 2, 17.20), (21, 12, 1, 29.20),
	(22, 5, 1, 19.80), (22, 14, 2, 33.00),
	(23, 8, 2, 23.10), (23, 19, 1, 40.10),
	(24, 10, 1, 26.20), (24, 21, 2, 43.00),
	(25, 6, 2, 20.30), (25, 18, 1, 38.60);

UPDATE Deal d
SET TotalAmount = sub.total_amount
FROM (
	SELECT DealID, SUM(Quantity * Price) AS total_amount
	FROM DealProduct
	GROUP BY DealID
) sub
WHERE sub.DealID = d.DealID;


\connect east_branch

TRUNCATE TABLE DealProduct, Deal, ProductCategory, Category, Product, Customer RESTART IDENTITY CASCADE;

INSERT INTO Customer (Name) VALUES
	('East Customer 01'), ('East Customer 02'), ('East Customer 03'), ('East Customer 04'), ('East Customer 05'),
	('East Customer 06'), ('East Customer 07'), ('East Customer 08'), ('East Customer 09'), ('East Customer 10'),
	('East Customer 11'), ('East Customer 12'), ('East Customer 13'), ('East Customer 14'), ('East Customer 15'),
	('East Customer 16'), ('East Customer 17'), ('East Customer 18'), ('East Customer 19'), ('East Customer 20'),
	('East Customer 21'), ('East Customer 22'), ('East Customer 23'), ('East Customer 24'), ('East Customer 25');

INSERT INTO Product (Name, CatalogPrice) VALUES
	('East Product 01', 12.40), ('East Product 02', 14.80), ('East Product 03', 16.50), ('East Product 04', 18.10), ('East Product 05', 19.70),
	('East Product 06', 21.20), ('East Product 07', 23.80), ('East Product 08', 25.30), ('East Product 09', 27.60), ('East Product 10', 29.10),
	('East Product 11', 31.40), ('East Product 12', 33.90), ('East Product 13', 35.20), ('East Product 14', 36.70), ('East Product 15', 38.40),
	('East Product 16', 40.20), ('East Product 17', 41.80), ('East Product 18', 43.50), ('East Product 19', 45.10), ('East Product 20', 46.80),
	('East Product 21', 48.30), ('East Product 22', 49.90), ('East Product 23', 51.40), ('East Product 24', 52.80), ('East Product 25', 54.30);

INSERT INTO Category (Name) VALUES
	('East Category Home'),
	('East Category Office'),
	('East Category Sport'),
	('East Category Kids'),
	('East Category Garden'),
	('East Category Tech'),
	('East Category Beauty'),
	('East Category Outdoors');

INSERT INTO ProductCategory (ProductID, CategoryID) VALUES
	(1, 1),  (1, 3),
	(2, 2),  (2, 4),
	(3, 3),  (3, 5),
	(4, 4),  (4, 6),
	(5, 5),  (5, 7),
	(6, 6),  (6, 8),
	(7, 7),  (7, 1),
	(8, 8),  (8, 2),
	(9, 1),  (9, 4),
	(10, 2), (10, 5),
	(11, 3), (11, 6),
	(12, 4), (12, 7),
	(13, 5), (13, 8),
	(14, 6), (14, 1),
	(15, 7), (15, 2),
	(16, 8), (16, 3),
	(17, 1), (17, 5),
	(18, 2), (18, 6),
	(19, 3), (19, 7),
	(20, 4), (20, 8),
	(21, 5), (21, 1),
	(22, 6), (22, 2),
	(23, 7), (23, 3),
	(24, 8), (24, 4),
	(25, 1), (25, 6);

INSERT INTO Deal (CustomerID, TotalAmount, DealDate) VALUES
	(1, 0, '2024-02-01'), (2, 0, '2024-02-02'), (3, 0, '2024-02-03'), (4, 0, '2024-02-04'), (5, 0, '2024-02-05'),
	(6, 0, '2024-02-06'), (7, 0, '2024-02-07'), (8, 0, '2024-02-08'), (9, 0, '2024-02-09'), (10, 0, '2024-02-10'),
	(11, 0, '2024-02-11'), (12, 0, '2024-02-12'), (13, 0, '2024-02-13'), (14, 0, '2024-02-14'), (15, 0, '2024-02-15'),
	(16, 0, '2024-02-16'), (17, 0, '2024-02-17'), (18, 0, '2024-02-18'), (19, 0, '2024-02-19'), (20, 0, '2024-02-20'),
	(21, 0, '2024-02-21'), (22, 0, '2024-02-22'), (23, 0, '2024-02-23'), (24, 0, '2024-02-24'), (25, 0, '2024-02-25');

INSERT INTO DealProduct (DealID, ProductID, Quantity, Price) VALUES
	(1, 1, 1, 12.00),  (1, 6, 2, 20.80),
	(2, 2, 2, 14.50),  (2, 7, 1, 23.40),
	(3, 3, 1, 16.30),  (3, 8, 2, 24.90),
	(4, 4, 1, 17.80),  (4, 9, 2, 27.10),
	(5, 5, 3, 19.20),  (5, 10, 1, 28.70),
	(6, 6, 1, 21.20),  (6, 11, 1, 31.10),
	(7, 7, 2, 23.60),  (7, 12, 2, 33.40),
	(8, 8, 2, 25.00),  (8, 13, 1, 35.00),
	(9, 9, 1, 27.60),  (9, 14, 2, 36.20),
	(10, 10, 1, 29.00), (10, 15, 3, 37.80),
	(11, 11, 2, 31.00), (11, 16, 1, 40.00),
	(12, 12, 1, 33.60), (12, 17, 2, 41.30),
	(13, 13, 2, 35.10), (13, 18, 1, 43.10),
	(14, 14, 1, 36.50), (14, 19, 2, 44.70),
	(15, 15, 2, 38.00), (15, 20, 1, 46.40),
	(16, 16, 1, 40.20), (16, 21, 2, 47.90),
	(17, 17, 2, 41.60), (17, 22, 1, 49.30),
	(18, 18, 1, 43.20), (18, 23, 2, 50.80),
	(19, 19, 3, 44.60), (19, 24, 1, 52.10),
	(20, 20, 1, 46.30), (20, 25, 2, 53.70),
	(21, 4, 1, 18.00), (21, 12, 2, 33.20),
	(22, 6, 2, 21.00), (22, 18, 1, 43.00),
	(23, 9, 1, 27.20), (23, 20, 2, 46.00),
	(24, 11, 2, 30.80), (24, 22, 1, 49.60),
	(25, 8, 2, 25.10), (25, 24, 1, 52.40);

UPDATE Deal d
SET TotalAmount = sub.total_amount
FROM (
	SELECT DealID, SUM(Quantity * Price) AS total_amount
	FROM DealProduct
	GROUP BY DealID
) sub
WHERE sub.DealID = d.DealID;

