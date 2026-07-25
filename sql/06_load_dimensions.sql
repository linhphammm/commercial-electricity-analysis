INSERT INTO warehouse.StateDIM (state_name)
VALUES
    ('New South Wales'),
    ('Victoria'),
    ('Queensland'),
    ('South Australia'),
    ('Western Australia'),
    ('Tasmania'),
    ('Northern Territory'),
    ('Australian Capital Territory'),
    ('Australia')
ON CONFLICT (state_name) DO NOTHING;

SELECT *
FROM warehouse.StateDIM
ORDER BY state_id;


-- Load retail data
INSERT INTO warehouse.RetailerDIM (retailer_name)
SELECT DISTINCT TRIM(retailer)
FROM staging.resident_customers
WHERE retailer IS NOT NULL
    AND TRIM(retailer) <> ''
ORDER BY TRIM(retailer);

SELECT *
FROM warehouse.RetailerDIM
ORDER BY retailer_id;


-- date
SELECT DISTINCT financial_year, YEAR
FROM staging.electricity_consumption
ORDER BY financial_year, YEAR;

SELECT DISTINCT financial_year, quarter
FROM staging.resident_retailers
ORDER BY financial_year, quarter;

SELECT DISTINCT financial_year, quarter
FROM staging.resident_customers
ORDER BY financial_year, quarter;

SELECT DISTINCT year
FROM staging.projected_households
ORDER BY year;

SELECT DISTINCT year, month 
FROM staging.monthly_spot_average
ORDER BY year, month;

SELECT DISTINCT date, year
FROM staging.population
ORDER BY date, year;

--ALTER TABLE warehouse.DateDIM
--ADD CONSTRAINT datedim_date_unique UNIQUE (date);

WITH monthly_spot_dates AS (
    SELECT DISTINCT
        MAKE_DATE(
            year,

            -- Convert month text such as Jan, JAN or jan
            -- into the corresponding month number.
            CASE UPPER(TRIM(month))
                WHEN 'JAN' THEN 1
                WHEN 'FEB' THEN 2
                WHEN 'MAR' THEN 3
                WHEN 'APR' THEN 4
                WHEN 'MAY' THEN 5
                WHEN 'JUN' THEN 6
                WHEN 'JUL' THEN 7
                WHEN 'AUG' THEN 8
                WHEN 'SEP' THEN 9
                WHEN 'OCT' THEN 10
                WHEN 'NOV' THEN 11
                WHEN 'DEC' THEN 12
            END,

            -- Use the first day as the representative date
            -- for each monthly observation.
            1
        ) AS source_date
    FROM staging.monthly_spot_average
    WHERE year IS NOT NULL
      AND month IS NOT NULL
),

financial_quarter_dates AS (
    SELECT DISTINCT
        (
            MAKE_DATE(
                start_year,

                -- Convert the financial quarter into its
                -- starting calendar month.
                CASE quarter
                    WHEN 1 THEN 7
                    WHEN 2 THEN 10
                    WHEN 3 THEN 1
                    WHEN 4 THEN 4
                END,

                -- Use the first day of the quarter.
                1
            )
            +
            CASE
                -- Q3 and Q4 occur in the second calendar year
                -- of the financial year.
                WHEN quarter IN (3, 4) THEN INTERVAL '1 year'

                -- Q1 and Q2 occur in the starting calendar year.
                ELSE INTERVAL '0 years'
            END
        )::DATE AS source_date

    FROM (
        SELECT
            -- Convert financial_year such as 2023-24 or
            -- 2023–24 into the starting year 2023.
            SPLIT_PART(
                REPLACE(financial_year, '–', '-'),
                '-',
                1
            )::INTEGER AS start_year,

            quarter

        FROM (
            -- Combine periods from both quarterly datasets.
            -- UNION removes duplicate year-quarter combinations.
            SELECT financial_year, quarter
            FROM staging.resident_retailers

            UNION

            SELECT financial_year, quarter
            FROM staging.resident_customers
        ) combined_periods

        WHERE financial_year IS NOT NULL
          AND quarter BETWEEN 1 AND 4
    ) cleaned_periods
),

all_dates AS (
    SELECT date AS source_date
    FROM staging.population
    WHERE date IS NOT NULL

    UNION

    SELECT source_date
    FROM monthly_spot_dates

    UNION

    SELECT MAKE_DATE(year, 1, 1) AS source_date
    FROM staging.projected_households
    WHERE year IS NOT NULL

    UNION

    SELECT MAKE_DATE(year, 1, 1) AS source_date
    FROM staging.median_weekly_earnings
    WHERE year IS NOT NULL

    UNION

    SELECT MAKE_DATE(year, 1, 1) AS source_date
    FROM staging.electricity_consumption
    WHERE year IS NOT NULL

    UNION

    select source_date
    from financial_quarter_dates
)

INSERT INTO warehouse.DateDIM (date, year, month, quarter)
SELECT DISTINCT
    source_date,
    EXTRACT(YEAR FROM source_date)::INTEGER AS year,
    EXTRACT(MONTH FROM source_date)::INTEGER AS month,
    EXTRACT(QUARTER FROM source_date)::INTEGER AS quarter
FROM all_dates
WHERE source_date IS NOT NULL
ON CONFLICT (date) DO NOTHING;
    

SELECT *
FROM warehouse.DateDIM
ORDER BY date_id;

-- population
INSERT INTO warehouse.PopulationFACT (date_id, state_id, population)
SELECT
    d.date_id,
    s.state_id,
    p.population
FROM staging.population p
JOIN warehouse.DateDIM d ON p.date = d.date
JOIN warehouse.StateDIM s ON p.state = s.state_name
WHERE p.date IS NOT NULL;

select *
from warehouse.PopulationFACT
order by population_id;


-- electricity consumption

--ALTER TABLE warehouse.ElectricityConsumptionFACT
--RENAME COLUMN terawatt_hours TO consumption_twh;
TRUNCATE TABLE warehouse.ElectricityConsumptionFACT
RESTART IDENTITY;
INSERT INTO warehouse.ElectricityConsumptionFACT (
    date_id,
    state_id,
    consumption_twh
)
SELECT
    d.date_id,
    s.state_id,
    ec.terawatt_hours
FROM staging.electricity_consumption ec
JOIN warehouse.DateDIM d
    ON MAKE_DATE(ec.year, 1, 1) = d.date
JOIN warehouse.StateDIM s
    ON TRIM(ec.state) = s.state_name
WHERE ec.year IS NOT NULL
  AND ec.terawatt_hours IS NOT NULL;



select *
from warehouse.ElectricityConsumptionFACT
order by electricity_consumption_id;


-- retailer
WITH retailer_data AS (
    SELECT 
        rr.retailer_count,
        CASE
            WHEN UPPER(TRIM(rr.state)) IN ('NSW', 'NEW SOUTH WALES')
                THEN 'New South Wales'
            WHEN UPPER(TRIM(rr.state)) IN ('VIC', 'VICTORIA')
                THEN 'Victoria'
            WHEN UPPER(TRIM(rr.state)) IN ('QLD', 'QUEENSLAND')
                THEN 'Queensland'
            WHEN UPPER(TRIM(rr.state)) IN ('SA', 'SOUTH AUSTRALIA')
                THEN 'South Australia'
            WHEN UPPER(TRIM(rr.state)) IN ('WA', 'WESTERN AUSTRALIA')
                THEN 'Western Australia'
            WHEN UPPER(TRIM(rr.state)) IN ('TAS', 'TASMANIA')
                THEN 'Tasmania'
            WHEN UPPER(TRIM(rr.state)) IN ('NT', 'NORTHERN TERRITORY')
                THEN 'Northern Territory'
            WHEN UPPER(TRIM(rr.state)) IN (
                'ACT',
                'AUSTRALIAN CAPITAL TERRITORY'
            )
                THEN 'Australian Capital Territory'
        ELSE TRIM(rr.state) 
        END AS standardized_state,

        (
            MAKE_DATE(
                SPLIT_PART(
                    REPLACE(rr.financial_year, '–', '-'),
                    '-',
                    1
                )::INTEGER,
                CASE rr.quarter
                    WHEN 1 THEN 7
                    WHEN 2 THEN 10
                    WHEN 3 THEN 1
                    WHEN 4 THEN 4
                END,
                1
            )
            +
            CASE
                WHEN rr.quarter IN (3, 4) THEN INTERVAL '1 year'
                ELSE INTERVAL '0 years'
            END
        )::DATE AS source_date
    FROM staging.resident_retailers rr
    WHERE rr.financial_year IS NOT NULL
      AND rr.quarter BETWEEN 1 AND 4
      AND rr.retailer_count IS NOT NULL
)

INSERT INTO warehouse.RetailersFACT (date_id, state_id, retailer_count)
SELECT
    d.date_id,
    s.state_id,
    rd.retailer_count
FROM retailer_data rd
JOIN warehouse.DateDIM d ON rd.source_date = d.date
JOIN warehouse.StateDIM s ON rd.standardized_state = s.state_name;


-- CUSTOMER FACT TABLE
-- customers
--ALTER TABLE warehouse.CustomersFACT
--ADD COLUMN state_id INTEGER
--REFERENCES warehouse.StateDIM(state_id);
WITH customer_data AS (
    SELECT
        TRIM(rc.retailer) AS retailer_name,
        rc.resident_cust_count AS customer_count,

        (
            MAKE_DATE(
                SPLIT_PART(
                    REPLACE(rc.financial_year, '–', '-'),
                    '-',
                    1
                )::INTEGER,

                CASE rc.quarter
                    WHEN 1 THEN 7
                    WHEN 2 THEN 10
                    WHEN 3 THEN 1
                    WHEN 4 THEN 4
                END,

                1
            )
            +
            CASE
                WHEN rc.quarter IN (3, 4)
                    THEN INTERVAL '1 year'
                ELSE INTERVAL '0 years'
            END
        )::DATE AS source_date

    FROM staging.resident_customers rc

    WHERE rc.financial_year IS NOT NULL
      AND rc.quarter BETWEEN 1 AND 4
      AND rc.retailer IS NOT NULL
      AND TRIM(rc.retailer) <> ''
      AND rc.resident_cust_count IS NOT NULL
)

INSERT INTO warehouse.CustomersFACT (
    date_id,
    retailer_id,
    customer_count
)
SELECT
    d.date_id,

    r.retailer_id,
    cd.customer_count
FROM customer_data cd

JOIN warehouse.DateDIM d
    ON cd.source_date = d.date

JOIN warehouse.RetailerDIM r
    ON cd.retailer_name = r.retailer_name;


select *
from warehouse.CustomersFACT
order by customers_id;

--projected households
--ALTER TABLE warehouse.ProjectedHouseholdsFACT
--ADD CONSTRAINT projected_households_date_state_unique
--UNIQUE (date_id, state_id);
INSERT INTO warehouse.ProjectedHouseholdsFACT (
    date_id,
    state_id,
    households
)
SELECT
    d.date_id,
    s.state_id,
    ph.households
FROM staging.projected_households ph
JOIN warehouse.DateDIM d
    ON MAKE_DATE(ph.year, 1, 1) = d.date
JOIN warehouse.StateDIM s
    ON TRIM(ph.state) = s.state_name
WHERE ph.households IS NOT NULL
ON CONFLICT (date_id, state_id) DO UPDATE
SET households = EXCLUDED.households;



-- projected household increase
INSERT INTO warehouse.ProjectedHouseholdsIncreaseFACT (
    state_id,
    households_increase
)
SELECT
    s.state_id,
    phi.households_increase
FROM staging.projected_households_increase phi
JOIN warehouse.StateDIM s
    ON TRIM(phi.state) = s.state_name
WHERE phi.households_increase IS NOT NULL;

select *
from warehouse.ProjectedHouseholdsIncreaseFACT;


-- ============================================================
-- Load SpotPricesFACT
--
-- Each row represents monthly spot-price information
-- for one state.
-- ============================================================

WITH spot_price_data AS (
    SELECT
        sp.min_spot,
        sp.max_spot,
        sp.vol_weighted_av_price,

        CASE
            WHEN UPPER(TRIM(sp.state)) IN ('NSW', 'NEW SOUTH WALES')
                THEN 'New South Wales'
            WHEN UPPER(TRIM(sp.state)) IN ('VIC', 'VICTORIA')
                THEN 'Victoria'
            WHEN UPPER(TRIM(sp.state)) IN ('QLD', 'QUEENSLAND')
                THEN 'Queensland'
            WHEN UPPER(TRIM(sp.state)) IN ('SA', 'SOUTH AUSTRALIA')
                THEN 'South Australia'
            WHEN UPPER(TRIM(sp.state)) IN ('WA', 'WESTERN AUSTRALIA')
                THEN 'Western Australia'
            WHEN UPPER(TRIM(sp.state)) IN ('TAS', 'TASMANIA')
                THEN 'Tasmania'
            WHEN UPPER(TRIM(sp.state)) IN ('NT', 'NORTHERN TERRITORY')
                THEN 'Northern Territory'
            WHEN UPPER(TRIM(sp.state)) IN (
                'ACT',
                'AUSTRALIAN CAPITAL TERRITORY'
            )
                THEN 'Australian Capital Territory'
            ELSE TRIM(sp.state)
        END AS standardized_state,

        MAKE_DATE(
            sp.year,
            CASE UPPER(TRIM(sp.month))
                WHEN 'JAN' THEN 1
                WHEN 'FEB' THEN 2
                WHEN 'MAR' THEN 3
                WHEN 'APR' THEN 4
                WHEN 'MAY' THEN 5
                WHEN 'JUN' THEN 6
                WHEN 'JUL' THEN 7
                WHEN 'AUG' THEN 8
                WHEN 'SEP' THEN 9
                WHEN 'OCT' THEN 10
                WHEN 'NOV' THEN 11
                WHEN 'DEC' THEN 12
            END,
            1
        ) AS source_date

    FROM staging.monthly_spot_average sp

    WHERE sp.year IS NOT NULL
      AND sp.month IS NOT NULL
      AND (
          sp.min_spot IS NOT NULL
          OR sp.max_spot IS NOT NULL
          OR sp.vol_weighted_av_price IS NOT NULL
      )
)

INSERT INTO warehouse.SpotPricesFACT (
    date_id,
    state_id,
    min_spot,
    max_spot,
    vol_weighted_av_price
)
SELECT
    d.date_id,
    s.state_id,
    spd.min_spot,
    spd.max_spot,
    spd.vol_weighted_av_price
FROM spot_price_data spd
JOIN warehouse.DateDIM d
    ON spd.source_date = d.date
JOIN warehouse.StateDIM s
    ON spd.standardized_state = s.state_name;


ALTER TABLE warehouse.SpotPricesFACT
ADD CONSTRAINT spot_prices_date_state_unique
UNIQUE (date_id, state_id);



INSERT INTO warehouse.IncomeFACT (
    date_id,
    state_id,
    median_weekly_income
)
SELECT
    d.date_id,
    s.state_id,
    i.median_income
FROM staging.median_weekly_earnings i
JOIN warehouse.DateDIM d
    ON d.date = MAKE_DATE(i.year, 1, 1)
JOIN warehouse.StateDIM s
    ON s.state_name = i.state
WHERE i.median_income IS NOT NULL;

select *
from warehouse.IncomeFACT;

