
-- Customer + market potential 
-- population by year and state
SELECT d.year, s.state_name, SUM(p.population) AS population_count
FROM
    warehouse.PopulationFACT AS p
JOIN
    warehouse.StateDIM AS s ON p.state_id = s.state_id
JOIN
    warehouse.DateDIM AS d ON p.date_id = d.date_id
GROUP BY
    d.year, s.state_name
ORDER BY
    d.year, s.state_name;


-- projected houehold increase
SELECT 
    s.state_name, 
    h.households_increase
FROM
    warehouse.ProjectedHouseholdsIncreaseFACT AS h
JOIN
    warehouse.StateDIM AS s ON h.state_id = s.state_id
ORDER BY
    s.state_name;

-- projected households numbers
-- butterfly chart???
SELECT 
    d.year, 
    s.state_name, 
    h.households
FROM
    warehouse.ProjectedHouseholdsFACT AS h
JOIN
    warehouse.StateDIM AS s ON h.state_id = s.state_id
JOIN
    warehouse.DateDIM AS d ON h.date_id = d.date_id
ORDER BY
    d.year, s.state_name;


-- Median weekly income by state and year
SELECT d.year, s.state_name, i.median_weekly_income
FROM
    warehouse.IncomeFACT AS i
JOIN
    warehouse.StateDIM AS s ON i.state_id = s.state_id
JOIN
    warehouse.DateDIM AS d ON i.date_id = d.date_id
ORDER BY
    d.year, s.state_name;




-- market demand
-- consumption
SELECT s.state_name, d.year, c.consumption_twh
FROM
    warehouse.electricityConsumptionFACT AS c
JOIN
    warehouse.StateDIM AS s ON c.state_id = s.state_id
JOIN
    warehouse.DateDIM AS d ON c.date_id = d.date_id
ORDER BY
    d.year, s.state_name;

-- retailers
SELECT s.state_name, d.year, r.retailer_count
FROM
    warehouse.RetailersFACT AS r
JOIN
    warehouse.StateDIM AS s ON r.state_id = s.state_id
JOIN
    warehouse.DateDIM AS d ON r.date_id = d.date_id
WHERE
    d.quarter = 2
ORDER BY
    d.year, s.state_name;


 

