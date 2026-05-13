
PC Sales Data Engineering Project

Overview
- Source: `pc_data.csv` (~10k rows). Contains location, shop, product, customer, pricing, dates, finance and operational attributes.
- Notes: `de_info.txt` requested a star schema design, staging and datawarehouse databases, dimension and fact tables, stored procedures, and SSIS-based automation.

Inferred Logical Model (Star Schema)
- Fact: `fact_sales`
  - Measures: cost_price, sale_price, discount_amount, finance_amount, cost_of_repairs, total_sales_per_employee
  - Use surrogate `sales_key` as primary key; natural business keys in source used for deduplication.

- Dimensions:
  - `dim_date` — purchase and ship date attributes
  - `dim_location` — continent / country_or_state / province_or_city
  - `dim_shop` — shop_name, shop_age
  - `dim_product` — pc_make, pc_model, storage_type, storage_capacity, ram, pc_market_price
  - `dim_customer` — customer_name, customer_surname, contact_number, email
  - `dim_sales_person` — sales_person_name, department

Medallion Layers
- Bronze: raw CSV files and `stg_pc_sales` (raw text preserved)
- Silver: typed, cleansed dimensions and de-duplicated `fact_sales` with surrogate keys
- Gold: curated, aggregated business tables (sales_by_month, top_products, sales_per_region)

What I added
- `sql/create_tables.sql` — DDL for staging, dimensions, and fact
- `sql/medallion_mapping.md` — mapping notes and sample SQL for Bronze→Silver→Gold

What I will do now (cleaning)
- Format and tidy SQL and MD files
- Add T-SQL stored-procedure templates to support Bronze→Silver loads
- Provide a short SSIS guidance file with skeleton steps

Tell me which specific automation or artifact you want next: SSIS skeleton, SSIS + SQL Agent job templates, or sample ETL scripts.

**Star Schema**
- **DDL:** dw star-schema DDL is available at [sql/star_schema.sql](sql/star_schema.sql).
- **Diagram:** visual diagram of the star schema is at [diagrams/star_schema.svg](diagrams/star_schema.svg).
- **Summary:** central fact table `fact_sales` links to dimensions `dim_date`, `dim_location`, `dim_shop`, `dim_product`, `dim_customer`, and `dim_sales_person` using surrogate keys; see DDL for PK/FK and index recommendations.

**ETL Helpers**
- `sql/select_distincts.sql` — cleaned `SELECT DISTINCT` queries to seed dimensions and populate `dim_date`.
- `sql/stored_procedures.sql` — T-SQL templates (`usp_load_stg_pc_sales`, `usp_load_dim_*`, `usp_load_fact_sales`) for Bronze→Silver loads.
- `sql/create_tables.sql` — staging DDL for `stg_pc_sales` (raw bronze load).

How to use
- Stage files: copy `pc_data.csv` to your Bronze location or load into `stg_pc_sales` (see `usp_load_stg_pc_sales`).
- Seed dims: run `sql/select_distincts.sql` SELECTs wrapped in `INSERT ... WHERE NOT EXISTS` or run the procedures in `sql/stored_procedures.sql`.
- Load facts: run `usp_load_fact_sales` after dims and `dim_date` are populated.

Next suggested steps
- Generate an SSIS package skeleton and SQL Agent job templates (`ssis/README.md`).
- Create a small Python ETL script to run the SELECTs and perform idempotent inserts locally.
- Run profiling and build Gold aggregates (examples can be added to `sql/`).

If you'd like, I can now generate the SSIS skeleton or a Python ETL runner — which do you prefer?
