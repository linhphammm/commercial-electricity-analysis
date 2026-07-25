
DROP TABLE IF EXISTS warehouse.IncomeFACT;
DROP TABLE IF EXISTS warehouse.SpotPricesFACT;
DROP TABLE IF EXISTS warehouse.ProjectedHouseholdsIncreaseFACT;
DROP TABLE IF EXISTS warehouse.ProjectedHouseholdsFACT;
DROP TABLE IF EXISTS warehouse.CustomersFACT;
DROP TABLE IF EXISTS warehouse.RetailersFACT;
DROP TABLE IF EXISTS warehouse.ElectricityConsumptionFACT;
DROP TABLE IF EXISTS warehouse.PopulationFACT;


DROP TABLE IF EXISTS warehouse.RetailerDIM;
DROP TABLE IF EXISTS warehouse.DateDIM;
DROP TABLE IF EXISTS warehouse.StateDIM;


CREATE TABLE IF NOT EXISTS warehouse.StateDIM (
    state_id INTEGER GENERATED ALWAYS AS IDENTITY,
    state_name VARCHAR(100) NOT NULL UNIQUE,

    PRIMARY KEY (state_id)
);


CREATE TABLE IF NOT EXISTS warehouse.DateDIM (
    date_id INTEGER GENERATED ALWAYS AS IDENTITY,
    date DATE,
    year INTEGER,
    month INTEGER,
    quarter INTEGER NOT NULL,

    PRIMARY KEY (date_id)
);


CREATE TABLE IF NOT EXISTS warehouse.RetailerDIM (
    retailer_id INTEGER GENERATED ALWAYS AS IDENTITY,
    retailer_name VARCHAR(100) NOT NULL,

    PRIMARY KEY (retailer_id)
);


CREATE TABLE IF NOT EXISTS warehouse.PopulationFACT (
    population_id INTEGER GENERATED ALWAYS AS IDENTITY,
    date_id INTEGER NOT NULL REFERENCES warehouse.DateDIM(date_id),
    state_id INTEGER NOT NULL REFERENCES warehouse.StateDIM(state_id),
    year INTEGER,
    population BIGINT,

    PRIMARY KEY (population_id)
);


CREATE TABLE IF NOT EXISTS warehouse.ElectricityConsumptionFACT (
    electricity_consumption_id INTEGER GENERATED ALWAYS AS IDENTITY,
    date_id INTEGER NOT NULL REFERENCES warehouse.DateDIM(date_id),
    state_id INTEGER NOT NULL REFERENCES warehouse.StateDIM(state_id),
    terawatt_hours NUMERIC(14,2),

    PRIMARY KEY (electricity_consumption_id)
);



CREATE TABLE IF NOT EXISTS warehouse.RetailersFACT (
    resident_retailers_id INTEGER GENERATED ALWAYS AS IDENTITY,
    date_id INTEGER NOT NULL REFERENCES warehouse.DateDIM(date_id),
    state_id INTEGER NOT NULL REFERENCES warehouse.StateDIM(state_id),
    retailer_count INTEGER,

    PRIMARY KEY (resident_retailers_id)
);


CREATE TABLE IF NOT EXISTS warehouse.CustomersFACT (
    customers_id INTEGER GENERATED ALWAYS AS IDENTITY,
    date_id INTEGER NOT NULL REFERENCES warehouse.DateDIM(date_id),
    retailer_id INTEGER NOT NULL REFERENCES warehouse.RetailerDIM(retailer_id),
    customer_count INTEGER,

    PRIMARY KEY (customers_id)
);


CREATE TABLE IF NOT EXISTS warehouse.ProjectedHouseholdsFACT (
    projected_households_id INTEGER GENERATED ALWAYS AS IDENTITY,
    date_id INTEGER NOT NULL REFERENCES warehouse.DateDIM(date_id),
    state_id INTEGER NOT NULL REFERENCES warehouse.StateDIM(state_id),
    households BIGINT,

    PRIMARY KEY (projected_households_id)
);


CREATE TABLE IF NOT EXISTS warehouse.ProjectedHouseholdsIncreaseFACT (
    projected_households_increase_id INTEGER GENERATED ALWAYS AS IDENTITY,
    state_id INTEGER NOT NULL REFERENCES warehouse.StateDIM(state_id),
    households_increase NUMERIC(14, 3),

    PRIMARY KEY (projected_households_increase_id)
);


CREATE TABLE IF NOT EXISTS warehouse.SpotPricesFACT (
    price_id INTEGER GENERATED ALWAYS AS IDENTITY,
    date_id INTEGER NOT NULL REFERENCES warehouse.DateDIM(date_id),
    state_id INTEGER NOT NULL REFERENCES warehouse.StateDIM(state_id),
    min_spot NUMERIC(14, 2),
    max_spot NUMERIC(14, 2),
    vol_weighted_av_price NUMERIC(14, 2),
    month VARCHAR(10),
    year INTEGER,

    PRIMARY KEY (price_id)
);



CREATE TABLE IF NOT EXISTS warehouse.IncomeFACT (
    income_id INTEGER GENERATED ALWAYS AS IDENTITY,
    date_id INTEGER NOT NULL REFERENCES warehouse.DateDIM(date_id),
    state_id INTEGER NOT NULL REFERENCES warehouse.StateDIM(state_id),
    median_weekly_income NUMERIC(12, 2),

    PRIMARY KEY (income_id)
);