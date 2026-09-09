-- SILVER LAYER

-- MODEL :
-- 1. DIM CITY
-- 2. DIM LOCALITY - BRIDGE RESTAURANT CUISINE --> DIM CUISINE
-- 3. FACT RESTAURANT
-- 4. FACT MENU ITEM - DIM MENU ITEM, DIM PRICE BAND

-- DIM CITY
CREATE OR REPLACE TABLE
zomato_market_intelligence.silver.dim_city
USING DELTA
AS
SELECT
    ROW_NUMBER() OVER (
        ORDER BY city
    ) AS city_key,

    city AS city_name,

    LOWER(TRIM(city)) AS city_normalized

FROM (
    SELECT DISTINCT
        TRIM(city) AS city
    FROM zomato_market_intelligence.bronze.stg_zomato_restaurant_items
    WHERE city IS NOT NULL
);

-- Validate CITY DIMENSION
SELECT *
FROM zomato_market_intelligence.silver.dim_city
ORDER BY city_key;

SELECT COUNT(*) AS city_count
FROM zomato_market_intelligence.silver.dim_city;


-- DIM LOCALITY
CREATE OR REPLACE TABLE
zomato_market_intelligence.silver.dim_locality
USING DELTA
AS
SELECT
    ROW_NUMBER() OVER (
        ORDER BY s.city, s.locality
    ) AS locality_key,

    c.city_key,

    s.locality AS locality_name,

    s.city_locality_key

FROM (
    SELECT DISTINCT
        TRIM(city) AS city,
        TRIM(locality) AS locality,
        city_locality_key
    FROM zomato_market_intelligence.bronze.stg_zomato_restaurant_items
    WHERE locality IS NOT NULL
) s

INNER JOIN zomato_market_intelligence.silver.dim_city c
    ON LOWER(TRIM(s.city))
       = c.city_normalized;


-- Validate Localities
SELECT
    COUNT(*) AS locality_count
FROM zomato_market_intelligence.silver.dim_locality;

SELECT
    c.city_name,
    COUNT(l.locality_key) AS locality_count

FROM zomato_market_intelligence.silver.dim_city c

LEFT JOIN zomato_market_intelligence.silver.dim_locality l
    ON c.city_key = l.city_key

GROUP BY c.city_name
ORDER BY locality_count DESC;


-- DIM CUISINE
CREATE OR REPLACE TABLE
zomato_market_intelligence.silver.dim_cuisine
USING DELTA
AS
SELECT
    ROW_NUMBER() OVER (
        ORDER BY cuisine
    ) AS cuisine_key,

    cuisine AS cuisine_name

FROM (
    SELECT DISTINCT
        TRIM(cuisine) AS cuisine
    FROM zomato_market_intelligence.bronze.stg_zomato_restaurant_items
    WHERE cuisine IS NOT NULL
);

-- Validate Cuisine
SELECT COUNT(*)
FROM zomato_market_intelligence.silver.dim_cuisine;


-- DIM PRICE BAND
CREATE OR REPLACE TABLE
zomato_market_intelligence.silver.dim_price_band
(
    price_band_key INT,
    price_band STRING,
    min_price DECIMAL(10,2),
    max_price DECIMAL(10,2),
    business_description STRING
)
USING DELTA;

INSERT INTO zomato_market_intelligence.silver.dim_price_band
VALUES
(1, 'Budget', 0, 150, 'Affordable menu items'),
(2, 'Mid-Range', 151, 300, 'Mainstream pricing'),
(3, 'Premium', 301, 600, 'Premium menu items'),
(4, 'Luxury', 601, NULL, 'High-priced menu items');


-- DIM MENU ITEM
CREATE OR REPLACE TABLE
zomato_market_intelligence.silver.dim_menu_item
USING DELTA
AS
SELECT
    ROW_NUMBER() OVER (
        ORDER BY item_name
    ) AS menu_item_key,

    item_name,

    ANY_VALUE(dietary_tag) AS dietary_tag,

    ANY_VALUE(best_seller_category)
        AS best_seller_category

FROM zomato_market_intelligence.bronze.stg_zomato_restaurant_items

WHERE item_name IS NOT NULL

GROUP BY item_name;

-- VALIDATE
SELECT COUNT(*)
FROM zomato_market_intelligence.silver.dim_menu_item;


-- DIM RESTAURANT
CREATE OR REPLACE TABLE
zomato_market_intelligence.silver.dim_restaurant
USING DELTA
AS
SELECT
    s.restaurant_key,

    ANY_VALUE(s.restaurant_name)
        AS restaurant_name,

    ANY_VALUE(c.city_key)
        AS city_key,

    ANY_VALUE(l.locality_key)
        AS locality_key

FROM zomato_market_intelligence.bronze.stg_zomato_restaurant_items s

INNER JOIN zomato_market_intelligence.silver.dim_city c
    ON LOWER(TRIM(s.city))
       = c.city_normalized

INNER JOIN zomato_market_intelligence.silver.dim_locality l
    ON s.city_locality_key
       = l.city_locality_key

GROUP BY
    s.restaurant_key;


-- Critical Restaurant Grain Test
SELECT
    COUNT(*) AS rows,
    COUNT(DISTINCT restaurant_key) AS unique_restaurants
FROM zomato_market_intelligence.silver.dim_restaurant;

-- Create Cuisine Bridge
CREATE OR REPLACE TABLE
zomato_market_intelligence.silver.bridge_restaurant_cuisine
USING DELTA
AS
SELECT DISTINCT

    s.restaurant_key,

    c.cuisine_key

FROM zomato_market_intelligence.bronze.stg_zomato_restaurant_items s

INNER JOIN zomato_market_intelligence.silver.dim_cuisine c

    ON TRIM(s.cuisine)
       = c.cuisine_name;

-- Validate Cuisine Bridge
SELECT
    restaurant_key,
    COUNT(*) AS cuisine_count

FROM zomato_market_intelligence.silver.bridge_restaurant_cuisine

GROUP BY restaurant_key

ORDER BY cuisine_count DESC;


-- FACT RESTAURANT
CREATE OR REPLACE TABLE
zomato_market_intelligence.silver.fact_restaurant
USING DELTA
AS
SELECT

    restaurant_key,

    ANY_VALUE(city_key)
        AS city_key,

    ANY_VALUE(locality_key)
        AS locality_key,

    ANY_VALUE(dining_rating)
        AS dining_rating,

    ANY_VALUE(delivery_rating)
        AS delivery_rating,

    ANY_VALUE(dining_votes)
        AS dining_votes,

    ANY_VALUE(delivery_votes)
        AS delivery_votes,

    ANY_VALUE(total_votes)
        AS total_votes,

    ANY_VALUE(fulfillment_score)
        AS fulfillment_score,

    ANY_VALUE(restaurant_density)
        AS restaurant_density,

    ANY_VALUE(same_cuisine_count)
        AS same_cuisine_count,

    ANY_VALUE(market_saturation_score)
        AS market_saturation_score,

    ANY_VALUE(expansion_opportunity_score)
        AS expansion_opportunity_score,

    ANY_VALUE(is_dining_rating_missing)
        AS is_dining_rating_missing,

    ANY_VALUE(is_delivery_rating_missing)
        AS is_delivery_rating_missing,

    ANY_VALUE(is_dining_votes_missing)
        AS is_dining_votes_missing,

    ANY_VALUE(is_delivery_votes_missing)
        AS is_delivery_votes_missing

FROM zomato_market_intelligence.bronze.stg_zomato_restaurant_items

GROUP BY restaurant_key;


-- Validate Fact Restaurant
SELECT
    COUNT(*) AS rows,
    COUNT(DISTINCT restaurant_key) AS restaurants
FROM zomato_market_intelligence.silver.fact_restaurant;


-- FACT MENU ITEM
CREATE OR REPLACE TABLE
zomato_market_intelligence.silver.fact_menu_item
USING DELTA
AS
SELECT

    s.restaurant_key,

    m.menu_item_key,

    c.cuisine_key,

    CASE
        WHEN s.item_price <= 150 THEN 1
        WHEN s.item_price <= 300 THEN 2
        WHEN s.item_price <= 600 THEN 3
        ELSE 4
    END AS price_band_key,

    s.item_price,

    s.item_votes,

    CASE
        WHEN UPPER(TRIM(s.best_seller_category))
             != 'NOT MARKED'
             AND s.best_seller_category IS NOT NULL
        THEN TRUE
        ELSE FALSE
    END AS is_best_seller_marked

FROM zomato_market_intelligence.bronze.stg_zomato_restaurant_items s

LEFT JOIN zomato_market_intelligence.silver.dim_menu_item m
    ON s.item_name = m.item_name

LEFT JOIN zomato_market_intelligence.silver.dim_cuisine c
    ON TRIM(s.cuisine) = c.cuisine_name

WHERE s.item_name IS NOT NULL;


-- Validate Menu Fact
SELECT
    COUNT(*) AS menu_fact_rows,
    COUNT(DISTINCT restaurant_key) AS restaurants,
    COUNT(DISTINCT menu_item_key) AS menu_items
FROM zomato_market_intelligence.silver.fact_menu_item;


-- FOREIGN KEY / ORPHAN Tests
-- Restaurant orphan test
SELECT COUNT(*) AS orphan_count

FROM zomato_market_intelligence.silver.fact_restaurant f

LEFT JOIN zomato_market_intelligence.silver.dim_restaurant d
    ON f.restaurant_key = d.restaurant_key

WHERE d.restaurant_key IS NULL;

-- City orphan test
SELECT COUNT(*) AS orphan_count

FROM zomato_market_intelligence.silver.fact_restaurant f

LEFT JOIN zomato_market_intelligence.silver.dim_city d
    ON f.city_key = d.city_key

WHERE d.city_key IS NULL;

-- Locality orphan test
SELECT COUNT(*) AS orphan_count

FROM zomato_market_intelligence.silver.fact_restaurant f

LEFT JOIN zomato_market_intelligence.silver.dim_locality d
    ON f.locality_key = d.locality_key

WHERE d.locality_key IS NULL;

-- Menu item orphan test
SELECT COUNT(*) AS orphan_count

FROM zomato_market_intelligence.silver.fact_menu_item f

LEFT JOIN zomato_market_intelligence.silver.dim_menu_item d
    ON f.menu_item_key = d.menu_item_key

WHERE d.menu_item_key IS NULL;