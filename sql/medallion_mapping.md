
Medallion Mapping and Transformation Notes

Bronze (raw ingestion)
- Store raw CSV files in `bronze/pc_sales/` (object store) or load to `stg_pc_sales` in a `staging` database. Preserve original text values and capture ingestion metadata (file name, ingest_ts).

Silver (cleansed & typed)
- Tasks:
	- Parse and validate `purchase_date` and `ship_date`; populate `dim_date` with `date_key` = YYYYMMDD.
	- Normalize contact numbers and lowercase/trim emails.
	- Cast numeric fields with `TRY_CAST` and treat 'N/A' as NULL.
	- Deduplicate and load dimension tables: `dim_product`, `dim_shop`, `dim_customer`, `dim_sales_person`, `dim_location`.
	- Load `fact_sales` using surrogate keys; apply deduplication logic (hash of business key or change data capture).

Example (Silver load sketch)
-- Populate `dim_product`
-- INSERT INTO dim_product (pc_make, pc_model, storage_type, storage_capacity, ram, pc_market_price)
-- SELECT DISTINCT TRIM(pc_make), TRIM(pc_model), TRIM(storage_type), TRIM(storage_capacity), TRIM(ram), TRY_CAST(pc_market_price AS DECIMAL(18,2))
-- FROM stg_pc_sales;

-- Populate `fact_sales` (resolve surrogate keys via joins)

Gold (curated)
- Create analytic tables and materialized views:
	- `gold.sales_by_month` (year, month, revenue, units_sold)
	- `gold.top_products` (top N by revenue)
	- `gold.customer_lifetime_value`

Automation notes
- Implement the flows with SSIS or another orchestrator:
	1. Ingest raw files → Bronze (file copy + load staging)
	2. Run Silver transforms (stored procedures) to populate dims and fact
	3. Run Gold aggregations and refresh materialized tables
- Schedule jobs with SQL Agent; add logging steps to record row counts, durations, and success/failure.

Provenance & quality checks
- Record `ingest_ts`, `source_file`, and row counts at each layer.
- Add checks for nulls in expected-not-null fields, negative prices, or invalid dates; alert or quarantine failing rows.

