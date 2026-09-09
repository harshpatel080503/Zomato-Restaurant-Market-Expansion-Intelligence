-- STEP 1 - UPLOAD DATASET

-- STEP 2 - KEEP CATALOG : zomato_market_intelligence

-- STEP 3 - KEEP SCHEMA : bronze

-- STEP 4 - TABLE NAME : stg_zomato_restaurant_items

-- STEP 5 - CREATE TABLE

-- VERIFY BRONZE TABLE
SELECT *
FROM zomato_market_intelligence.bronze.stg_zomato_restaurant_items
LIMIT 20;

SELECT COUNT(*) AS row_count
FROM zomato_market_intelligence.bronze.stg_zomato_restaurant_items;

-- Inspect Schema
DESCRIBE TABLE
zomato_market_intelligence.bronze.stg_zomato_restaurant_items;

-- Bronze Layer Validation
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT restaurant_key) AS restaurants,
    COUNT(DISTINCT city) AS cities,
    COUNT(DISTINCT city_locality_key) AS city_localities,
    COUNT(DISTINCT cuisine) AS cuisines,
    COUNT(DISTINCT item_name) AS menu_items
FROM zomato_market_intelligence.bronze.stg_zomato_restaurant_items;