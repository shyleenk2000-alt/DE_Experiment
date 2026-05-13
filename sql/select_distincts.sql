/*
  Clean SELECT DISTINCT queries for building dimension seed data from `stg_pc_sales`.
  - Use these as the basis for INSERT ... SELECT DISTINCT INTO dim_* or as dedupe queries in ETL.
  - T-SQL compatible; adapt function names if using another SQL dialect.
*/

-- 1) Products (dim_product)
SELECT DISTINCT
  TRIM(pc_make)                           AS pc_make,
  TRIM(pc_model)                          AS pc_model,
  NULLIF(TRIM(storage_type), '')         AS storage_type,
  NULLIF(TRIM(storage_capacity), '')     AS storage_capacity,
  NULLIF(TRIM(ram), '')                  AS ram,
  TRY_CAST(NULLIF(pc_market_price, '') AS DECIMAL(18,2)) AS pc_market_price
FROM stg_pc_sales
WHERE pc_make IS NOT NULL AND LTRIM(RTRIM(pc_make)) <> ''
;

-- 2) Shops (dim_shop)
SELECT DISTINCT
  TRIM(shop_name)                         AS shop_name,
  TRY_CAST(NULLIF(shop_age, '') AS INT)   AS shop_age
FROM stg_pc_sales
WHERE shop_name IS NOT NULL AND LTRIM(RTRIM(shop_name)) <> ''
;

-- 3) Locations (dim_location)
SELECT DISTINCT
  TRIM(continent)                         AS continent,
  TRIM(country_or_state)                  AS country_or_state,
  NULLIF(TRIM(province_or_city),'')       AS province_or_city
FROM stg_pc_sales
WHERE continent IS NOT NULL AND LTRIM(RTRIM(continent)) <> ''
;

-- 4) Customers (dim_customer) -- normalize contact and lowercase emails
SELECT DISTINCT
  NULLIF(TRIM(customer_name),'')          AS customer_name,
  NULLIF(TRIM(customer_surname),'')       AS customer_surname,
  NULLIF(
    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(customer_contact_number),' ',''),'-',''),'.',''),'(',''),')',''),'x','')
  ,'')                                      AS contact_number_normalized,
  LOWER(NULLIF(TRIM(customer_email_address),'')) AS email_lower
FROM stg_pc_sales
WHERE customer_contact_number IS NOT NULL AND LTRIM(RTRIM(customer_contact_number)) <> ''
;

-- 5) Sales persons (dim_sales_person)
SELECT DISTINCT
  TRIM(sales_person_name)                 AS sales_person_name,
  NULLIF(TRIM(sales_person_department),'') AS department
FROM stg_pc_sales
WHERE sales_person_name IS NOT NULL AND LTRIM(RTRIM(sales_person_name)) <> ''
;

-- 6) Dates (dim_date) - union of purchase_date and ship_date (skip 'N/A')
WITH raw_dates AS (
  SELECT DISTINCT TRY_CAST(NULLIF(purchase_date,'N/A') AS DATE) AS full_date FROM stg_pc_sales
  UNION
  SELECT DISTINCT TRY_CAST(NULLIF(ship_date,'N/A') AS DATE) AS full_date FROM stg_pc_sales
)
SELECT DISTINCT
  CONVERT(INT, CONVERT(CHAR(8), full_date, 112)) AS date_key,
  full_date,
  DATEPART(YEAR, full_date)  AS [year],
  DATEPART(QUARTER, full_date) AS quarter,
  DATEPART(MONTH, full_date) AS [month],
  DATEPART(DAY, full_date)   AS [day],
  DATEPART(WEEKDAY, full_date) AS weekday
FROM raw_dates
WHERE full_date IS NOT NULL
ORDER BY date_key
;

-- Usage notes:
-- - Wrap these SELECTs inside INSERT ... SELECT with an anti-join (NOT EXISTS) to perform idempotent inserts.
-- - For production, prefer using MERGE or SCD logic for dimensions and CDC/watermarks for fact loads.
-- Example idempotent insert pattern for dim_product:
-- INSERT INTO dw.dim_product (pc_make, pc_model, storage_type, storage_capacity, ram, pc_market_price)
-- SELECT p.* FROM (
--   <the product SELECT DISTINCT above>
-- ) p
-- WHERE NOT EXISTS (
--   SELECT 1 FROM dw.dim_product d WHERE d.pc_make = p.pc_make AND d.pc_model = p.pc_model
-- );
