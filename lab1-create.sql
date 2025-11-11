-- Enable UUID generator once per database
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Customer master data
CREATE TABLE Customer (
    CustomerID SERIAL PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    RowGuid UUID DEFAULT gen_random_uuid() UNIQUE,
    ModifiedDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Product catalogue
CREATE TABLE Product (
    ProductID SERIAL PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    CatalogPrice DECIMAL(10, 2) NOT NULL,
    RowGuid UUID DEFAULT gen_random_uuid() UNIQUE,
    ModifiedDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Product categories
CREATE TABLE Category (
    CategoryID SERIAL PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    RowGuid UUID DEFAULT gen_random_uuid() UNIQUE,
    ModifiedDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Category assignment bridge
CREATE TABLE ProductCategory (
    ProductID INT REFERENCES Product(ProductID) ON DELETE CASCADE,
    CategoryID INT REFERENCES Category(CategoryID) ON DELETE CASCADE,
    RowGuid UUID DEFAULT gen_random_uuid() UNIQUE,
    ModifiedDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ProductID, CategoryID)
);

-- Sales header
CREATE TABLE Deal (
    DealID SERIAL PRIMARY KEY,
    CustomerID INT REFERENCES Customer(CustomerID) ON DELETE CASCADE,
    TotalAmount DECIMAL(10, 2) NOT NULL,
    DealDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    RowGuid UUID DEFAULT gen_random_uuid() UNIQUE,
    ModifiedDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sales line items
CREATE TABLE DealProduct (
    DealID INT REFERENCES Deal(DealID) ON DELETE CASCADE,
    ProductID INT REFERENCES Product(ProductID) ON DELETE CASCADE,
    Quantity INT NOT NULL,
    Price DECIMAL(10, 2) NOT NULL,
    RowGuid UUID DEFAULT gen_random_uuid() UNIQUE,
    ModifiedDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (DealID, ProductID)
);



