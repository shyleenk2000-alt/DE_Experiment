/* Stored procedure templates for Bronze -> Silver -> Gold loads
   These are T-SQL template procedures intended for a SQL Server environment.
   Adapt names and connection strings when implementing in SSIS packages.
*/

-- 1) Load raw CSV into staging (example: bulk insert or external table)
CREATE PROCEDURE usp_load_stg_pc_sales
    @filePath NVARCHAR(4000)
AS
BEGIN
    SET NOCOUNT ON;
    -- Example: use BULK INSERT or OPENROWSET(BULK...) depending on environment and permissions
    -- BULK INSERT stg_pc_sales FROM @filePath WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', TABLOCK);
    PRINT 'Implement bulk load from ' + @filePath;
END;

-- 2) Populate dim_product from staging (deduplicate)
CREATE PROCEDURE usp_load_dim_product
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dim_product (pc_make, pc_model, storage_type, storage_capacity, ram, pc_market_price)
    SELECT DISTINCT
        TRIM(pc_make), TRIM(pc_model), TRIM(storage_type), TRIM(storage_capacity), TRIM(ram), TRY_CAST(pc_market_price AS DECIMAL(18,2))
    FROM stg_pc_sales st
    WHERE pc_make IS NOT NULL AND pc_model IS NOT NULL
      AND NOT EXISTS (
          SELECT 1 FROM dim_product p
          WHERE p.pc_make = TRIM(st.pc_make) AND p.pc_model = TRIM(st.pc_model)
      );
END;

-- 3) Populate other dims (example for shop)
CREATE PROCEDURE usp_load_dim_shop
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dim_shop (shop_name, shop_age)
    SELECT DISTINCT TRIM(shop_name), TRY_CAST(shop_age AS INT)
    FROM stg_pc_sales st
    WHERE shop_name IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM dim_shop s WHERE s.shop_name = TRIM(st.shop_name));
END;

-- 4) Populate dim_customer
CREATE PROCEDURE usp_load_dim_customer
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dim_customer (customer_name, customer_surname, contact_number, email)
    SELECT DISTINCT TRIM(customer_name), TRIM(customer_surname), TRIM(customer_contact_number), TRIM(customer_email_address)
    FROM stg_pc_sales st
    WHERE customer_contact_number IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM dim_customer c WHERE c.contact_number = TRIM(st.customer_contact_number));
END;

-- 5) Populate dim_sales_person
CREATE PROCEDURE usp_load_dim_sales_person
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dim_sales_person (sales_person_name, department)
    SELECT DISTINCT TRIM(sales_person_name), TRIM(sales_person_department)
    FROM stg_pc_sales st
    WHERE sales_person_name IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM dim_sales_person sp WHERE sp.sales_person_name = TRIM(st.sales_person_name));
END;

-- 6) Load fact_sales joining to dims (simple, idempotent pattern)
CREATE PROCEDURE usp_load_fact_sales
AS
BEGIN
    SET NOCOUNT ON;

    -- Example: a simple INSERT that resolves surrogate keys by lookups
    INSERT INTO fact_sales (
        date_key, ship_date_key, location_key, shop_key, product_key, customer_key, sales_person_key,
        cost_price, sale_price, discount_amount, finance_amount, cost_of_repairs, total_sales_per_employee,
        channel, priority
    )
    SELECT
        d.date_key,
        sd.date_key,
        l.location_key,
        s.shop_key,
        p.product_key,
        c.customer_key,
        sp.sales_person_key,
        TRY_CAST(st.cost_price AS DECIMAL(18,2)),
        TRY_CAST(st.sale_price AS DECIMAL(18,2)),
        TRY_CAST(st.discount_amount AS DECIMAL(18,2)),
        TRY_CAST(st.finance_amount AS DECIMAL(18,2)),
        TRY_CAST(st.cost_of_repairs AS DECIMAL(18,2)),
        TRY_CAST(st.total_sales_per_employee AS DECIMAL(18,2)),
        TRIM(st.channel), TRIM(st.priority)
    FROM stg_pc_sales st
    LEFT JOIN dim_date d ON d.full_date = TRY_CAST(st.purchase_date AS DATE)
    LEFT JOIN dim_date sd ON sd.full_date = TRY_CAST(NULLIF(st.ship_date,'N/A') AS DATE)
    LEFT JOIN dim_location l ON l.continent = st.continent AND l.country_or_state = st.country_or_state AND l.province_or_city = st.province_or_city
    LEFT JOIN dim_shop s ON s.shop_name = TRIM(st.shop_name)
    LEFT JOIN dim_product p ON p.pc_make = TRIM(st.pc_make) AND p.pc_model = TRIM(st.pc_model)
    LEFT JOIN dim_customer c ON c.contact_number = TRIM(st.customer_contact_number)
    LEFT JOIN dim_sales_person sp ON sp.sales_person_name = TRIM(st.sales_person_name)
    -- Consider adding WHERE filters to avoid re-inserting existing business keys; use CDC or watermark for production
    ;
END;
