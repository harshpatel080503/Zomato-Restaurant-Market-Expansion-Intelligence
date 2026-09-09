-- Gold View 1 - City Performance 
CREATE OR REPLACE VIEW
zomato_market_intelligence.gold.vw_city_performance
AS

SELECT

    c.city_key,

    c.city_name,

    COUNT(DISTINCT f.restaurant_key)
        AS restaurant_count,

    ROUND(AVG(f.dining_rating), 2)
        AS avg_dining_rating,

    ROUND(AVG(f.delivery_rating), 2)
        AS avg_delivery_rating,

    SUM(f.dining_votes)
        AS dining_vote_volume,

    SUM(f.delivery_votes)
        AS delivery_vote_volume,

    ROUND(AVG(f.fulfillment_score), 2)
        AS avg_fulfillment_score,

    ROUND(AVG(f.market_saturation_score), 3)
        AS avg_saturation_score,

    ROUND(AVG(f.expansion_opportunity_score), 3)
        AS avg_expansion_score

FROM zomato_market_intelligence.silver.fact_restaurant f

INNER JOIN zomato_market_intelligence.silver.dim_city c

    ON f.city_key = c.city_key

GROUP BY

    c.city_key,
    c.city_name;


-- Gold View 2 - Locality Performance
CREATE OR REPLACE VIEW
zomato_market_intelligence.gold.vw_locality_performance
AS

SELECT

    c.city_name,

    l.locality_key,

    l.locality_name,

    COUNT(DISTINCT f.restaurant_key)
        AS restaurant_count,

    ROUND(AVG(f.dining_rating), 2)
        AS avg_rating,

    ROUND(AVG(f.delivery_rating), 2)
        AS avg_delivery_rating,

    ROUND(AVG(f.restaurant_density), 2)
        AS restaurant_density,

    ROUND(AVG(f.market_saturation_score), 3)
        AS saturation_score,

    ROUND(AVG(f.expansion_opportunity_score), 3)
        AS expansion_score

FROM zomato_market_intelligence.silver.fact_restaurant f

INNER JOIN zomato_market_intelligence.silver.dim_locality l
    ON f.locality_key = l.locality_key

INNER JOIN zomato_market_intelligence.silver.dim_city c
    ON l.city_key = c.city_key

GROUP BY

    c.city_name,
    l.locality_key,
    l.locality_name;


-- Gold View 3 - Cuisine Opportunity
CREATE OR REPLACE VIEW
zomato_market_intelligence.gold.vw_cuisine_opportunity
AS

SELECT

    c.cuisine_key,

    c.cuisine_name,

    COUNT(DISTINCT b.restaurant_key)
        AS restaurant_count,

    COUNT(DISTINCT f.restaurant_key)
        AS restaurants_with_menu_data,

    ROUND(AVG(f.item_price), 2)
        AS avg_item_price,

    ROUND(AVG(f.item_votes), 2)
        AS avg_item_votes

FROM zomato_market_intelligence.silver.bridge_restaurant_cuisine b

INNER JOIN zomato_market_intelligence.silver.dim_cuisine c
    ON b.cuisine_key = c.cuisine_key

LEFT JOIN zomato_market_intelligence.silver.fact_menu_item f
    ON b.restaurant_key = f.restaurant_key
   AND b.cuisine_key = f.cuisine_key

GROUP BY

    c.cuisine_key,
    c.cuisine_name;


-- Gold View 4 - Pricing Analysis
CREATE OR REPLACE VIEW
zomato_market_intelligence.gold.vw_pricing_analysis
AS

SELECT

    p.price_band_key,

    p.price_band,

    COUNT(*) AS menu_item_count,

    COUNT(DISTINCT f.restaurant_key)
        AS restaurant_count,

    ROUND(AVG(f.item_price), 2)
        AS avg_item_price,

    ROUND(AVG(f.item_votes), 2)
        AS avg_item_votes,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN f.is_best_seller_marked
                THEN 1 ELSE 0
            END
        )
        / COUNT(*),
        2
    ) AS bestseller_rate

FROM zomato_market_intelligence.silver.fact_menu_item f

INNER JOIN zomato_market_intelligence.silver.dim_price_band p
    ON f.price_band_key = p.price_band_key

GROUP BY

    p.price_band_key,
    p.price_band;


-- Gold View 5 - Expansion Opportunity
CREATE OR REPLACE VIEW
zomato_market_intelligence.gold.vw_expansion_opportunity
AS

SELECT

    c.city_name,

    l.locality_name,

    COUNT(DISTINCT f.restaurant_key)
        AS restaurant_count,

    ROUND(AVG(f.dining_rating), 2)
        AS avg_rating,

    ROUND(AVG(f.delivery_rating), 2)
        AS avg_delivery_rating,

    ROUND(AVG(f.fulfillment_score), 2)
        AS fulfillment_score,

    ROUND(AVG(f.restaurant_density), 2)
        AS restaurant_density,

    ROUND(AVG(f.market_saturation_score), 3)
        AS saturation_score,

    ROUND(AVG(f.expansion_opportunity_score), 3)
        AS expansion_score

FROM zomato_market_intelligence.silver.fact_restaurant f

INNER JOIN zomato_market_intelligence.silver.dim_city c
    ON f.city_key = c.city_key

INNER JOIN zomato_market_intelligence.silver.dim_locality l
    ON f.locality_key = l.locality_key

GROUP BY

    c.city_name,
    l.locality_name;


-- Top 20 Expansion Opportunity
SELECT *

FROM zomato_market_intelligence.gold.vw_expansion_opportunity

ORDER BY expansion_score DESC

LIMIT 20;