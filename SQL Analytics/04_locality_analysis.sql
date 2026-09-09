-- Locality Analysis

-- Business Questions
-- 1. Which localities are underpenetrated?
-- 2. Which localities are overcrowded?
-- 3. Which localities combine quality with low saturation?
-- 4. Where should partner onboarding happen first?

CREATE OR REPLACE VIEW zomato_market_intelligence.gold.vw_locality_performance AS
SELECT
    c.city_name,
    l.locality_key,
    l.locality_name,
    COUNT(DISTINCT f.restaurant_key) AS restaurant_count,
    ROUND(AVG(f.dining_rating), 2) AS avg_dining_rating,
    ROUND(AVG(f.delivery_rating), 2) AS avg_delivery_rating,
    ROUND(AVG(f.restaurant_density), 2) AS avg_restaurant_density,
    ROUND(AVG(f.same_cuisine_count), 2) AS avg_same_cuisine_count,
    ROUND(AVG(f.market_saturation_score), 3) AS avg_saturation_score,
    ROUND(AVG(f.expansion_opportunity_score), 3) AS avg_expansion_score
FROM zomato_market_intelligence.silver.fact_restaurant f
JOIN zomato_market_intelligence.silver.dim_locality l
  ON f.locality_key = l.locality_key
JOIN zomato_market_intelligence.silver.dim_city c
  ON l.city_key = c.city_key
GROUP BY c.city_name, l.locality_key, l.locality_name;

-- Ranking Query
SELECT *
FROM zomato_market_intelligence.gold.vw_locality_performance
ORDER BY avg_expansion_score DESC;

-- Interpretation : High Opportunity + Low Saturation = Top Locality For Expansion