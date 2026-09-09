-- Executive KPI Layer

-- Business Question
-- 1. How Large is the restaurant network?
-- 2. How strong is the overall market?
-- 3. What is the average quality?
-- 4. How much engagement exists?
-- 5. What is the overall opportunity level?

SELECT
    COUNT(DISTINCT restaurant_key) AS total_restaurants,
    COUNT(DISTINCT city_key) AS total_cities,
    COUNT(DISTINCT locality_key) AS total_localities,
    ROUND(AVG(dining_rating), 2) AS avg_dining_rating,
    ROUND(AVG(delivery_rating), 2) AS avg_delivery_rating,
    SUM(dining_votes) AS total_dining_votes,
    SUM(delivery_votes) AS total_delivery_votes,
    ROUND(AVG(fulfillment_score), 2) AS avg_fulfillment_score,
    ROUND(AVG(restaurant_density), 2) AS avg_restaurant_density,
    ROUND(AVG(market_saturation_score), 3) AS avg_saturation_score,
    ROUND(AVG(expansion_opportunity_score), 3) AS avg_expansion_score
FROM zomato_market_intelligence.silver.fact_restaurant;