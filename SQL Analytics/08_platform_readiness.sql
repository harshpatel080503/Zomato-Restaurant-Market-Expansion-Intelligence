-- Platform Readiness Analysis

-- Business Questions
-- 1. Which markets are digitally ready?
-- 2. Which markets can scale delivery faster?
-- 3. Which markets are stronger for dine-in / booking?

CREATE OR REPLACE VIEW zomato_market_intelligence.gold.vw_platform_readiness AS
SELECT
    c.city_name,
    ROUND(1 - AVG(is_delivery_rating_missing), 3) AS delivery_capability_rate,
    ROUND(1 - AVG(is_dining_rating_missing), 3) AS dine_in_capability_rate,
    ROUND(AVG(CASE WHEN delivery_votes > 0 THEN 1 ELSE 0 END), 3) AS active_delivery_penetration
FROM zomato_market_intelligence.silver.fact_restaurant f
JOIN zomato_market_intelligence.silver.dim_city c
  ON f.city_key = c.city_key
GROUP BY c.city_name;

-- Interpretation : Higher readiness = easier expansion, lower operational friction.