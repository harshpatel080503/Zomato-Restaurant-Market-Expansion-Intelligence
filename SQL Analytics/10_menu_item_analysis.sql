-- Menu Item Analysis

-- Business Questions
-- 1. Which items are most popular?
-- 2. Which items are bestsellers?
-- 3. How do item prices relate to popularity?
-- 4. Which price bands have the strongest menu performance?

-- Top items by votes
SELECT
    m.item_name,
    SUM(f.item_votes) AS total_item_votes,
    AVG(f.item_price) AS avg_item_price
FROM zomato_market_intelligence.silver.fact_menu_item f
JOIN zomato_market_intelligence.silver.dim_menu_item m
    ON f.menu_item_key = m.menu_item_key
GROUP BY m.item_name
ORDER BY total_item_votes DESC
LIMIT 25;

-- BestSeller Analysis
SELECT
    is_best_seller_marked,
    COUNT(*) AS item_count,
    ROUND(AVG(item_price), 2) AS avg_price,
    ROUND(AVG(item_votes), 2) AS avg_votes
FROM zomato_market_intelligence.silver.fact_menu_item
GROUP BY is_best_seller_marked;

-- Menu item pricing vs popularity
SELECT
    p.price_band,
    ROUND(AVG(f.item_votes), 2) AS avg_item_votes,
    COUNT(*) AS item_count
FROM zomato_market_intelligence.silver.fact_menu_item f
JOIN zomato_market_intelligence.silver.dim_price_band p
  ON f.price_band_key = p.price_band_key
GROUP BY p.price_band
ORDER BY p.price_band;

-- Interpretation : This helps explain which item types and price bands drive interest.