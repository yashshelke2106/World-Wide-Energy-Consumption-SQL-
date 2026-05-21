use energydb2;

-- What are the top 5 countries by GDP in the most recent year?


SELECT Country, year, MAX(Value) AS GDP
FROM gdp_3
WHERE year = (SELECT MAX(year) FROM gdp_3)
GROUP BY Country, year
ORDER BY GDP DESC
LIMIT 5;


-- Compare energy production and consumption by country and year. 
SELECT p.country,p.year,
    SUM(p.production) AS total_production,
    SUM(c.consumption) AS total_consumption,
    (SUM(p.production) - SUM(c.consumption)) AS balance
FROM production p
JOIN consumption c ON p.country = c.country AND p.year = c.year
GROUP BY p.country, p.year
ORDER BY p.year, balance DESC;


-- Which energy types contribute most to emissions across all countries?
SELECT energy_type, SUM(emission) AS total_emission
FROM emission_3
GROUP BY energy_type
ORDER BY total_emission DESC;

-- How does energy production per capita vary across countries?
SELECT p.country, p.year, ROUND(SUM(p.production) / NULLIF(pop.Value,0), 4) AS production_per_capita
FROM production p
JOIN population pop ON p.country = pop.countries AND p.year = pop.year
GROUP BY p.country, p.year, pop.Value
ORDER BY p.year, production_per_capita DESC;

-- Which countries have the highest energy consumption relative to GDP?
SELECT c.country, c.year, SUM(c.consumption) AS total_consumption, g.Value AS GDP,
    ROUND(SUM(c.consumption) / NULLIF(g.Value,0), 4) AS consumption_per_gdp
FROM consumption c
JOIN gdp_3 g ON c.country = g.Country AND c.year = g.year
GROUP BY c.country, c.year, g.Value
ORDER BY consumption_per_gdp DESC;


-- Trend Analysis Over Time how have global emissions changed year over year?
SELECT year, SUM(emission) AS global_emissions
FROM emission_3
GROUP BY year
ORDER BY year;

-- What is the global share (%) of emissions by country?
WITH global_totals AS (SELECT year,SUM(emission) AS global_emission
    FROM emission_3
    GROUP BY year
)
SELECT e.country,e.year,SUM(e.emission) AS country_emission,
    g.global_emission,ROUND(SUM(e.emission) / g.global_emission * 100, 2) AS share_percent
FROM emission_3 e
JOIN global_totals g ON e.year = g.year
GROUP BY e.country, e.year, g.global_emission
ORDER BY e.year, share_percent DESC;

-- What is the global average GDP, emission, and population by year?
WITH avg_gdp AS (SELECT year, AVG(Value) AS avg_gdp
    FROM gdp_3
    GROUP BY year
),
avg_emission AS (SELECT year, AVG(emission) AS avg_emission
    FROM emission_3
    GROUP BY year
),
avg_population AS (SELECT year, AVG(Value) AS avg_population
    FROM population
    GROUP BY year
)

-- What is the global average GDP, emission, and population by year?
SELECT g.year, g.avg_gdp, e.avg_emission, p.avg_population
FROM avg_gdp g
LEFT JOIN avg_emission e ON g.year = e.year
LEFT JOIN avg_population p ON g.year = p.year
ORDER BY g.year;

-- What is the total emission per country for the most recent year available?
WITH latest_year AS (SELECT MAX(year) AS yr
    FROM emission_3
)
SELECT e.country, SUM(e.emission) AS total_emission
FROM emission_3 e
JOIN latest_year ly ON e.year = ly.yr
GROUP BY e.country
ORDER BY total_emission DESC;


-- Total consumption per year
SELECT country, year, total_consumption
FROM (
    SELECT p.country, p.year, SUM(c.consumption) AS total_consumption,
           ROW_NUMBER() OVER (PARTITION BY p.year ORDER BY SUM(c.consumption) DESC) AS rn
    FROM production p
    JOIN consumption c ON p.country = c.country AND p.year = c.year
    GROUP BY p.country, p.year
) t
WHERE rn = 1
ORDER BY year;

-- Highest per capita through years
SELECT country, year, production_per_capita
FROM (
    SELECT p.country,
           p.year,
           ROUND(SUM(p.production) / NULLIF(pop.Value,0), 4) AS production_per_capita,
           ROW_NUMBER() OVER (PARTITION BY p.year ORDER BY SUM(p.production) / NULLIF(pop.Value,0) DESC) AS rn
    FROM production p
    JOIN population pop 
      ON p.country = pop.countries AND p.year = pop.year
    GROUP BY p.country, p.year, pop.Value
) t
WHERE rn = 1
ORDER BY year;
