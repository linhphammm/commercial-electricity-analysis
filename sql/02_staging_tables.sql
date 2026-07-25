CREATE TABLE IF NOT EXISTS staging.population (
    date DATE,
    year INTEGER,
    state VARCHAR(100),
    population BIGINT
);

CREATE TABLE IF NOT EXISTS staging.electricity_consumption (
    financial_year VARCHAR(20),
    year INTEGER,
    state VARCHAR(100),
    terawatt_hours NUMERIC(14,2)
);

CREATE TABLE IF NOT EXISTS staging.resident_retailers (
    financial_year VARCHAR(20),
    quarter INTEGER,
    state VARCHAR(100),
    retailer_count INTEGER
);

CREATE TABLE IF NOT EXISTS staging.resident_customers (
    financial_year VARCHAR(20),
    quarter INTEGER,
    retailer VARCHAR(100),
    resident_cust_count INTEGER
);

DROP TABLE TABLE staging.projected_households;
CREATE TABLE IF NOT EXISTS staging.projected_households (
    state VARCHAR(100),
    year INTEGER,
    households BIGINT
);


DROP TABLE IF EXISTS staging.projected_households_increase;
CREATE TABLE staging.projected_households_increase (
    state VARCHAR(100),
    households_increase NUMERIC(14, 3)
);


CREATE TABLE IF NOT EXISTS staging.monthly_spot_average (
    year INTEGER,
    month VARCHAR(10),
    state VARCHAR(20),
    min_spot NUMERIC(14, 2),
    max_spot NUMERIC(14, 2),
    vol_weighted_av_price NUMERIC(14, 2)
);

CREATE TABLE IF NOT EXISTS staging.median_weekly_earnings (
    year INTEGER,
    state VARCHAR(100),
    median_income NUMERIC(12, 2)
);