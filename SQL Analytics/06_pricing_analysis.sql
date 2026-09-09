-- Pricing Analysis

-- Business Questions
-- 1. Which Price bands dominate?
-- 2. Any markets budget-heavy or premium-heavy?
-- 3. Which price bands are missing in a city/locality?
-- 4. Does pricing align with popularity?

CREATE OR REPLACE VIEW zomato_market_intelligence.gold.vw_pricing_analysis AS
SELECT
    p.price_band_key,
    p.price_band,
    COUNT(*) AS menu_item_count,
    COUNT(DISTINCT f.restaurant_key) AS restaurant_count,
    ROUND(AVG(f.item_price), 2) AS avg_item_price,
    ROUND(AVG(f.item_votes), 2) AS avg_item_votes,
    ROUND(
        100.0 * SUM(CASE WHEN f.is_best_seller_marked THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS bestseller_rate
FROM zomato_market_intelligence.silver.fact_menu_item f
JOIN zomato_market_intelligence.silver.dim_price_band p
  ON f.price_band_key = p.price_band_key
GROUP BY p.price_band_key, p.price_band;

-- Pricing by City
SELECT
    city.city_name,
    p.price_band,
    COUNT(*) AS menu_item_count
FROM zomato_market_intelligence.silver.fact_menu_item f
JOIN zomato_market_intelligence.silver.dim_price_band p
  ON f.price_band_key = p.price_band_key
JOIN zomato_market_intelligence.silver.fact_restaurant r
  ON f.restaurant_key = r.restaurant_key
JOIN zomato_market_intelligence.silver.dim_city city
  ON r.city_key = city.city_key
GROUP BY city.city_name, p.price_band
ORDER BY city.city_name, p.price_band;

-- Interpretation : A market with only budget items and no premium presence may have a pricing gap.