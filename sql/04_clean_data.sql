-- Count Rows
SELECT 'population' AS table_name, COUNT(*) AS row_count
FROM staging.population
UNION ALL
SELECT 'electricity_consumption' AS table_name, COUNT(*) AS row_count
FROM staging.electricity_consumption
UNION ALL
SELECT 'resident_retailers' AS table_name, COUNT(*) AS row_count
FROM staging.resident_retailers
UNION ALL
SELECT 'resident_customers' AS table_name, COUNT(*) AS row_count
FROM staging.resident_customers
UNION ALL
SELECT 'projected_households' AS table_name, COUNT(*) AS row_count
FROM staging.projected_households
UNION ALL
SELECT 'projected_households_increase' AS table_name, COUNT(*) AS row_count
FROM staging.projected_households_increase
UNION ALL
SELECT 'monthly_spot_average' AS table_name, COUNT(*) AS row_count
FROM staging.monthly_spot_average
UNION ALL
SELECT 'median_weekly_earnings' AS table_name, COUNT(*) AS row_count
FROM staging.median_weekly_earnings


-- Check for Nulls
SELECT *
FROM staging.population
WHERE date IS NULL 
OR year IS NULL 
OR state IS NULL 
OR population IS NULL

SELECT * 
FROM staging.electricity_consumption
WHERE financial_year IS NULL
OR year IS NULL
OR state IS NULL
OR terawatt_hours IS NULL;

SELECT *
FROM staging.resident_retailers
WHERE financial_year IS NULL
OR quarter IS NULL
OR state IS NULL
OR retailer_count IS NULL;

-- HAS 3 NULLS
SELECT *
FROM staging.resident_customers
WHERE financial_year IS NULL
OR quarter IS NULL
OR retailer IS NULL
OR resident_cust_count IS NULL;

SELECT *
FROM staging.projected_households
WHERE state IS NULL
OR year IS NULL
OR households IS NULL;

SELECT *
FROM staging.projected_households_increase
WHERE state IS NULL
OR households_increase IS NULL;

SELECT *
FROM staging.monthly_spot_average
WHERE year IS NULL
OR month IS NULL
OR state IS NULL
OR min_spot IS NULL
OR max_spot IS NULL
OR vol_weighted_av_price IS NULL;

-- 18 NULLS
SELECT COUNT(*)
FROM staging.median_weekly_earnings
WHERE year IS NULL
OR state IS NULL
OR median_income IS NULL;

-- inspecting to standardize state names
SELECT DISTINCT 
    TRIM(state) as state,
    source_table
FROM (
    SELECT state, 'population' AS source_table FROM staging.population 
    UNION ALL
    SELECT state, 'electricity_consumption' AS source_table FROM staging.electricity_consumption
    UNION ALL
    SELECT state, 'resident_retailers' AS source_table FROM staging.resident_retailers
    UNION ALL
    SELECT state, 'projected_households' AS source_table FROM staging.projected_households
    UNION ALL
    SELECT state, 'projected_households_increase' AS source_table FROM staging.projected_households_increase
    UNION ALL
    SELECT state, 'monthly_spot_average' AS source_table FROM staging.monthly_spot_average
    UNION ALL
    SELECT state, 'median_weekly_earnings' AS source_table FROM staging.median_weekly_earnings
) combined_states -- temp name for queries inside
ORDER BY state, source_table;

