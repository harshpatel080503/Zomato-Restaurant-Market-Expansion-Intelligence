-- Cuisine Analysis

-- Business Questions
-- 1. Which cuisines dominate the market?
-- 2. Which cuisines are underrepresented?
-- 3. Which cuisines should be targeted for growth?
-- 4. Which cities / localities have cuisine gaps?

CREATE OR REPLACE VIEW zomato_market_intelligence.gold.vw_cuisine_opportunity AS
SELECT
    c.cuisine_key,
    c.cuisine_name,
    COUNT(DISTINCT b.restaurant_key) AS restaurant_count
FROM zomato_market_intelligence.silver.bridge_restaurant_cuisine b
JOIN zomato_market_intelligence.silver.dim_cuisine c
  ON b.cuisine_key = c.cuisine_key
GROUP BY c.cuisine_key, c.cuisine_name;

--Cuisine by city
SELECT
    city.city_name,
    cuisine.cuisine_name,
    COUNT(DISTINCT b.restaurant_key) AS restaurant_count
FROM zomato_market_intelligence.silver.bridge_restaurant_cuisine b
JOIN zomato_market_intelligence.silver.dim_cuisine cuisine
  ON b.cuisine_key = cuisine.cuisine_key
JOIN zomato_market_intelligence.silver.fact_restaurant f
  ON b.restaurant_key = f.restaurant_key
JOIN zomato_market_intelligence.silver.dim_city city
  ON f.city_key = city.city_key
GROUP BY city.city_name, cuisine.cuisine_name
ORDER BY city.city_name, restaurant_count DESC;

-- Cuisine Concentration
WITH cuisine_share AS (
    SELECT
        city.city_name,
        cuisine.cuisine_name,
        COUNT(DISTINCT b.restaurant_key) AS restaurant_count,
        SUM(COUNT(DISTINCT b.restaurant_key)) OVER (PARTITION BY city.city_name) AS city_total
    FROM zomato_market_intelligence.silver.bridge_restaurant_cuisine b
    JOIN zomato_market_intelligence.silver.dim_cuisine cuisine
      ON b.cuisine_key = cuisine.cuisine_key
    JOIN zomato_market_intelligence.silver.fact_restaurant f
      ON b.restaurant_key = f.restaurant_key
    JOIN zomato_market_intelligence.silver.dim_city city
      ON f.city_key = city.city_key
    GROUP BY city.city_name, cuisine.cuisine_name
)
SELECT
    city_name,
    SUM(POWER(restaurant_count * 1.0 / city_total, 2)) AS cuisine_concentration_index
FROM cuisine_share
GROUP BY city_name
ORDER BY cuisine_concentration_index DESC;

-- Interpretation : Higher Cuisine Concentration = Less Variety = Possible Cuisine Gap.