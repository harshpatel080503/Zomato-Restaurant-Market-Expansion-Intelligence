-- Saturation Analysis
-- 1. Which markets are crowded?
-- 2. Which localities have too many similar restaurants?
-- 3. Where is competition intense?
-- 4. Where should Zomato avoid overinvestment?

CREATE OR REPLACE VIEW zomato_market_intelligence.gold.vw_saturation_analysis AS
SELECT
    c.city_name,
    l.locality_name,
    COUNT(DISTINCT f.restaurant_key) AS restaurant_count,
    ROUND(AVG(f.restaurant_density), 2) AS avg_restaurant_density,
    ROUND(AVG(f.same_cuisine_count), 2) AS avg_same_cuisine_count,
    ROUND(AVG(f.market_saturation_score), 3) AS avg_saturation_score
FROM zomato_market_intelligence.silver.fact_restaurant f
JOIN zomato_market_intelligence.silver.dim_city c
  ON f.city_key = c.city_key
JOIN zomato_market_intelligence.silver.dim_locality l
  ON f.locality_key = l.locality_key
GROUP BY c.city_name, l.locality_name;

-- Interpretation : High Density + High Same Cuisine Count + High Saturation Score = Crowded Market