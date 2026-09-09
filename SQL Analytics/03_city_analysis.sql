-- City Analysis

-- Business Questions
-- 1. Which cities are most attractive?
-- 2. Which cities are saturated?
-- 3. Which cities have the strongest eatings and engagement?
-- 4. Which cities should be prioritized for expansion?

-- City KPI - restaurant count, locality count, average rating, vote volume, ssaturation score, opportunity score

CREATE OR REPLACE VIEW zomato_market_intelligence.gold.vw_city_performance AS
SELECT
    c.city_key,
    c.city_name,
    COUNT(DISTINCT f.restaurant_key) AS restaurant_count,
    COUNT(DISTINCT f.locality_key) AS locality_count,
    ROUND(AVG(f.dining_rating), 2) AS avg_dining_rating,
    ROUND(AVG(f.delivery_rating), 2) AS avg_delivery_rating,
    SUM(f.dining_votes) AS dining_vote_volume,
    SUM(f.delivery_votes) AS delivery_vote_volume,
    ROUND(AVG(f.fulfillment_score), 2) AS avg_fulfillment_score,
    ROUND(AVG(f.market_saturation_score), 3) AS avg_saturation_score,
    ROUND(AVG(f.expansion_opportunity_score), 3) AS avg_expansion_score
FROM zomato_market_intelligence.silver.fact_restaurant f
JOIN zomato_market_intelligence.silver.dim_city c
  ON f.city_key = c.city_key
GROUP BY c.city_key, c.city_name;


-- Ranking Query
SELECT *
FROM zomato_market_intelligence.gold.vw_city_performance
ORDER BY avg_expansion_score DESC, avg_dining_rating DESC;

-- Interpretation
-- A city is attractive if: rating is strong, votes are healthy, saturation is moderate or low, expansion score is high


