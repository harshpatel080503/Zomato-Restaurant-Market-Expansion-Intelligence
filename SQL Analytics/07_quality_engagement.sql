-- Quality and Engagement Analysis

-- Business Questions
-- 1. Which markets have the best restaurant quality?
-- 2. Which markets have higher customer engagement?
-- 3. Are high ratings backed by meaningful vote volume?
-- 4. Which cuisines or cities are strongest on quality?

CREATE OR REPLACE VIEW zomato_market_intelligence.gold.vw_quality_analysis AS
SELECT
    c.city_name,
    ROUND(AVG(f.dining_rating), 2) AS avg_dining_rating,
    ROUND(AVG(f.delivery_rating), 2) AS avg_delivery_rating,
    SUM(f.dining_votes) AS dining_votes,
    SUM(f.delivery_votes) AS delivery_votes,
    ROUND(AVG(
        CASE
            WHEN f.dining_rating >= 4 THEN 1
            ELSE 0
        END
    ), 3) AS high_rating_share
FROM zomato_market_intelligence.silver.fact_restaurant f
JOIN zomato_market_intelligence.silver.dim_city c
  ON f.city_key = c.city_key
GROUP BY c.city_name;

-- Vote-weighted quality
SELECT
    c.city_name,
    ROUND(
        SUM(f.dining_rating * COALESCE(f.dining_votes, 0))
        / NULLIF(SUM(COALESCE(f.dining_votes, 0)), 0),
        2
    ) AS vote_weighted_dining_rating
FROM zomato_market_intelligence.silver.fact_restaurant f
JOIN zomato_market_intelligence.silver.dim_city c
  ON f.city_key = c.city_key
GROUP BY c.city_name;

-- Interpretation : Quality without votes is weak signal. Votes without quality are noisy signal.