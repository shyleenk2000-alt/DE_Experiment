/* Star schema DDL for Data Warehouse (T-SQL compatible) */
SET NOCOUNT ON;

-- Create dw schema if missing
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'dw')
    EXEC('CREATE SCHEMA dw');

-- Dimension: Date
IF OBJECT_ID('dw.dim_date') IS NULL
BEGIN
    CREATE TABLE dw.dim_date (
        date_key INT PRIMARY KEY, -- YYYYMMDD
        full_date DATE NOT NULL UNIQUE,
        year INT NOT NULL,
        quarter INT NOT NULL,
        month INT NOT NULL,
        day INT NOT NULL,
        weekday INT NOT NULL
    );
END

-- Dimension: Location
IF OBJECT_ID('dw.dim_location') IS NULL
BEGIN
    CREATE TABLE dw.dim_location (
        location_key INT IDENTITY(1,1) PRIMARY KEY,
        continent VARCHAR(100) NOT NULL,
        country_or_state VARCHAR(200) NOT NULL,
        province_or_city VARCHAR(200) NULL,
        CONSTRAINT ux_dim_location_unique UNIQUE (continent, country_or_state, province_or_city)
    );
    CREATE NONCLUSTERED INDEX idx_dim_location_country ON dw.dim_location(country_or_state);
END

-- Dimension: Shop
IF OBJECT_ID('dw.dim_shop') IS NULL
BEGIN
    CREATE TABLE dw.dim_shop (
        shop_key INT IDENTITY(1,1) PRIMARY KEY,
        shop_name VARCHAR(200) NOT NULL,
        shop_age INT NULL,
        CONSTRAINT ux_dim_shop_name UNIQUE (shop_name)
    );
    CREATE NONCLUSTERED INDEX idx_dim_shop_name ON dw.dim_shop(shop_name);
END

-- Dimension: Product
IF OBJECT_ID('dw.dim_product') IS NULL
BEGIN
    CREATE TABLE dw.dim_product (
        product_key INT IDENTITY(1,1) PRIMARY KEY,
        pc_make VARCHAR(100) NOT NULL,
        pc_model VARCHAR(200) NOT NULL,
        storage_type VARCHAR(50) NULL,
        storage_capacity VARCHAR(50) NULL,
        ram VARCHAR(50) NULL,
        pc_market_price DECIMAL(18,2) NULL,
        CONSTRAINT ux_dim_product_make_model UNIQUE (pc_make, pc_model)
    );
    CREATE NONCLUSTERED INDEX idx_dim_product_make ON dw.dim_product(pc_make);
END

-- Dimension: Customer
IF OBJECT_ID('dw.dim_customer') IS NULL
BEGIN
    CREATE TABLE dw.dim_customer (
        customer_key INT IDENTITY(1,1) PRIMARY KEY,
        customer_name VARCHAR(100) NULL,
        customer_surname VARCHAR(100) NULL,
        contact_number VARCHAR(100) NULL,
        email VARCHAR(200) NULL,
        CONSTRAINT ux_dim_customer_contact UNIQUE (contact_number)
    );
    CREATE NONCLUSTERED INDEX idx_dim_customer_email ON dw.dim_customer(email);
END

-- Dimension: Sales Person
IF OBJECT_ID('dw.dim_sales_person') IS NULL
BEGIN
    CREATE TABLE dw.dim_sales_person (
        sales_person_key INT IDENTITY(1,1) PRIMARY KEY,
        sales_person_name VARCHAR(200) NOT NULL,
        department VARCHAR(200) NULL,
        CONSTRAINT ux_dim_sales_person_name UNIQUE (sales_person_name)
    );
END

-- Fact table: Sales
IF OBJECT_ID('dw.fact_sales') IS NULL
BEGIN
    CREATE TABLE dw.fact_sales (
        sales_key BIGINT IDENTITY(1,1) PRIMARY KEY,
        date_key INT NOT NULL,
        ship_date_key INT NULL,
        location_key INT NOT NULL,
        shop_key INT NOT NULL,
        product_key INT NOT NULL,
        customer_key INT NULL,
        sales_person_key INT NULL,
        cost_price DECIMAL(18,2) NULL,
        sale_price DECIMAL(18,2) NULL,
        discount_amount DECIMAL(18,2) NULL,
        finance_amount DECIMAL(18,2) NULL,
        cost_of_repairs DECIMAL(18,2) NULL,
        total_sales_per_employee DECIMAL(18,2) NULL,
        channel VARCHAR(50) NULL,
        priority VARCHAR(50) NULL,
        CONSTRAINT fk_fact_date FOREIGN KEY (date_key) REFERENCES dw.dim_date(date_key),
        CONSTRAINT fk_fact_ship_date FOREIGN KEY (ship_date_key) REFERENCES dw.dim_date(date_key),
        CONSTRAINT fk_fact_location FOREIGN KEY (location_key) REFERENCES dw.dim_location(location_key),
        CONSTRAINT fk_fact_shop FOREIGN KEY (shop_key) REFERENCES dw.dim_shop(shop_key),
        CONSTRAINT fk_fact_product FOREIGN KEY (product_key) REFERENCES dw.dim_product(product_key),
        CONSTRAINT fk_fact_customer FOREIGN KEY (customer_key) REFERENCES dw.dim_customer(customer_key),
        CONSTRAINT fk_fact_sales_person FOREIGN KEY (sales_person_key) REFERENCES dw.dim_sales_person(sales_person_key)
    );
    CREATE NONCLUSTERED INDEX idx_fact_date ON dw.fact_sales(date_key);
    CREATE NONCLUSTERED INDEX idx_fact_location ON dw.fact_sales(location_key);
    CREATE NONCLUSTERED INDEX idx_fact_product ON dw.fact_sales(product_key);
END

/* Notes:
   - Populate dw.dim_date with a calendar table (YYYYMMDD keys) before loading facts.
   - Use surrogate keys and deduplication/upsert strategies when loading dimensions.
   - Consider partitioning `dw.fact_sales` by date_key for large volumes.
*/
