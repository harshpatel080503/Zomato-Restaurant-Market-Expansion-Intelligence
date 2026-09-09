-- Expansion Opportunity Scoring

-- Business Questions
-- 1. Which city / locality should Zomato prioritize?
-- 2. Which markets deserve top expansion attention?
-- 3. Which markets are weak or saturated?

CREATE OR REPLACE VIEW zomato_market_intelligence.gold.vw_expansion_opportunity AS
WITH base AS (
    SELECT
        c.city_name,
        l.locality_name,
        COUNT(DISTINCT f.restaurant_key) AS restaurant_count,
        ROUND(AVG(f.dining_rating), 2) AS avg_dining_rating,
        ROUND(AVG(f.delivery_rating), 2) AS avg_delivery_rating,
        ROUND(AVG(f.restaurant_density), 2) AS avg_restaurant_density,
        ROUND(AVG(f.same_cuisine_count), 2) AS avg_same_cuisine_count,
        ROUND(AVG(f.market_saturation_score), 3) AS avg_saturation_score,
        ROUND(AVG(f.expansion_opportunity_score), 3) AS avg_existing_expansion_score,
        SUM(f.dining_votes) AS dining_votes,
        SUM(f.delivery_votes) AS delivery_votes
    FROM zomato_market_intelligence.silver.fact_restaurant f
    JOIN zomato_market_intelligence.silver.dim_city c
      ON f.city_key = c.city_key
    JOIN zomato_market_intelligence.silver.dim_locality l
      ON f.locality_key = l.locality_key
    GROUP BY c.city_name, l.locality_name
),
scored AS (
    SELECT
        *,
        PERCENT_RANK() OVER (ORDER BY avg_dining_rating) AS rating_score,
        PERCENT_RANK() OVER (ORDER BY dining_votes) AS engagement_score,
        PERCENT_RANK() OVER (ORDER BY -avg_restaurant_density) AS coverage_score,
        PERCENT_RANK() OVER (ORDER BY -avg_saturation_score) AS saturation_penalty_score
    FROM base
)
SELECT
    *,
    ROUND(
        0.30 * rating_score +
        0.25 * engagement_score +
        0.25 * coverage_score +
        0.20 * saturation_penalty_score,
        3
    ) AS final_expansion_score
FROM scored;


-- Suggested Ranking
SELECT *
FROM zomato_market_intelligence.gold.vw_expansion_opportunity
ORDER BY final_expansion_score DESC
LIMIT 20;

-- Interpretation : This gives the final shortlist for expansion.


-- Market Segmentation
SELECT
    *,
    CASE
        WHEN final_expansion_score >= 0.75 THEN 'High Opportunity'
        WHEN final_expansion_score >= 0.50 THEN 'Medium Opportunity'
        ELSE 'Low Opportunity'
    END AS opportunity_band
FROM zomato_market_intelligence.gold.vw_expansion_opportunity;