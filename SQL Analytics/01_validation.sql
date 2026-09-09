-- Validation Layer

-- 2.1 Row Counts
SELECT 'fact_restaurant' AS table_name, COUNT(*) AS rows
FROM zomato_market_intelligence.silver.fact_restaurant
UNION ALL
SELECT 'fact_menu_item', COUNT(*)
FROM zomato_market_intelligence.silver.fact_menu_item
UNION ALL
SELECT 'dim_city', COUNT(*)
FROM zomato_market_intelligence.silver.dim_city
UNION ALL
SELECT 'dim_locality', COUNT(*)
FROM zomato_market_intelligence.silver.dim_locality
UNION ALL
SELECT 'dim_cuisine', COUNT(*)
FROM zomato_market_intelligence.silver.dim_cuisine
UNION ALL
SELECT 'dim_menu_item', COUNT(*)
FROM zomato_market_intelligence.silver.dim_menu_item;

-- 2.2 Duplicate key Checks
SELECT restaurant_key, COUNT(*) AS cnt
FROM zomato_market_intelligence.silver.fact_restaurant
GROUP BY restaurant_key
HAVING COUNT(*) > 1;

SELECT menu_item_key, COUNT(*) AS cnt
FROM zomato_market_intelligence.silver.dim_menu_item
GROUP BY menu_item_key
HAVING COUNT(*) > 1;

-- 2.3 Orphan Checks
SELECT COUNT(*) AS orphan_count
FROM zomato_market_intelligence.silver.fact_restaurant f
LEFT JOIN zomato_market_intelligence.silver.dim_restaurant d
    ON f.restaurant_key = d.restaurant_key
WHERE d.restaurant_key IS NULL;

-- 2.4 Data Sanity Checks
SELECT COUNT(*) AS invalid_ratings
FROM zomato_market_intelligence.silver.fact_restaurant
WHERE dining_rating < 0 OR dining_rating > 5
   OR delivery_rating < 0 OR delivery_rating > 5;

SELECT COUNT(*) AS invalid_prices
FROM zomato_market_intelligence.silver.fact_menu_item
WHERE item_price < 0;

SELECT COUNT(*) AS invalid_votes
FROM zomato_market_intelligence.silver.fact_menu_item
WHERE item_votes < 0;