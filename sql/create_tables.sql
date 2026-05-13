-- DDL for staging, dimension and fact tables (inferred from pc_data.csv)

-- Staging: keep raw columns as-is
CREATE TABLE stg_pc_sales (
  raw_id INT IDENTITY(1,1) PRIMARY KEY,
  continent VARCHAR(100),
  country_or_state VARCHAR(200),
  province_or_city VARCHAR(200),
  shop_name VARCHAR(200),
  shop_age INT,
  pc_make VARCHAR(100),
  pc_model VARCHAR(200),
  storage_type VARCHAR(50),
  customer_name VARCHAR(100),
  customer_surname VARCHAR(100),
  customer_contact_number VARCHAR(100),
  customer_email_address VARCHAR(200),
  sales_person_name VARCHAR(200),
  sales_person_department VARCHAR(200),
  cost_price DECIMAL(18,2),
  sale_price DECIMAL(18,2),
  payment_method VARCHAR(50),
  discount_amount DECIMAL(18,2),
  purchase_date VARCHAR(50),
  ship_date VARCHAR(50),
  finance_amount DECIMAL(18,2),
  ram VARCHAR(50),
  credit_score INT,
  channel VARCHAR(50),
  priority VARCHAR(50),
  cost_of_repairs DECIMAL(18,2),
  total_sales_per_employee DECIMAL(18,2),
  pc_market_price DECIMAL(18,2),
  storage_capacity VARCHAR(50)
);

-- Dimension: Date
CREATE TABLE dim_date (
  date_key INT PRIMARY KEY, -- YYYYMMDD
  full_date DATE,
  year INT,
  quarter INT,
  month INT,
  day INT,
  weekday INT
);

-- Dimension: Location
CREATE TABLE dim_location (
  location_key INT IDENTITY(1,1) PRIMARY KEY,
  continent VARCHAR(100),
  country_or_state VARCHAR(200),
  province_or_city VARCHAR(200)
);

-- Dimension: Shop
CREATE TABLE dim_shop (
  shop_key INT IDENTITY(1,1) PRIMARY KEY,
  shop_name VARCHAR(200),
  shop_age INT
);

-- Dimension: Product
CREATE TABLE dim_product (
  product_key INT IDENTITY(1,1) PRIMARY KEY,
  pc_make VARCHAR(100),
  pc_model VARCHAR(200),
  storage_type VARCHAR(50),
  storage_capacity VARCHAR(50),
  ram VARCHAR(50),
  pc_market_price DECIMAL(18,2)
);

-- Dimension: Customer
CREATE TABLE dim_customer (
  customer_key INT IDENTITY(1,1) PRIMARY KEY,
  customer_name VARCHAR(100),
  customer_surname VARCHAR(100),
  contact_number VARCHAR(100),
  email VARCHAR(200)
);

-- Dimension: Sales Person
CREATE TABLE dim_sales_person (
  sales_person_key INT IDENTITY(1,1) PRIMARY KEY,
  sales_person_name VARCHAR(200),
  department VARCHAR(200)
);

-- Fact table: Sales (surrogate keys to dims)
CREATE TABLE fact_sales (
  sales_key BIGINT IDENTITY(1,1) PRIMARY KEY,
  date_key INT,
  ship_date_key INT NULL,
  location_key INT,
  shop_key INT,
  product_key INT,
  customer_key INT,
  sales_person_key INT,
  cost_price DECIMAL(18,2),
  sale_price DECIMAL(18,2),
  discount_amount DECIMAL(18,2),
  finance_amount DECIMAL(18,2),
  cost_of_repairs DECIMAL(18,2),
  total_sales_per_employee DECIMAL(18,2),
  channel VARCHAR(50),
  priority VARCHAR(50)
);
