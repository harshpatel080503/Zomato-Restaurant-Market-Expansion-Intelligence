-- Restaurant Grain
-- For : quality, engagement, fulfillment, popularity
-- Features : dining_rating_norm, delivery_rating_norm,fulfillment_norm,quality_score, rating_completeness, dining_votes_log, delivery_votes_log, engagement_raw, engagement_score, restaurant_quality_band, restaurant_engagement_band

CREATE OR REPLACE TABLE
zomato_market_intelligence.silver.fe_restaurant
USING DELTA
AS

WITH base AS (

    SELECT
        restaurant_key,
        city_key,
        locality_key,

        dining_rating,
        delivery_rating,

        dining_votes,
        delivery_votes,

        fulfillment_score,

        restaurant_density,
        same_cuisine_count,

        market_saturation_score,
        expansion_opportunity_score,

        CASE
            WHEN dining_rating IS NOT NULL
            THEN dining_rating / 5.0
        END AS dining_rating_norm,

        CASE
            WHEN delivery_rating IS NOT NULL
            THEN delivery_rating / 5.0
        END AS delivery_rating_norm,

        CASE
            WHEN dining_rating IS NOT NULL
             AND delivery_rating IS NOT NULL
            THEN 1.0
            WHEN dining_rating IS NOT NULL
              OR delivery_rating IS NOT NULL
            THEN 0.5
            ELSE 0.0
        END AS rating_completeness,

        LN(1 + COALESCE(dining_votes, 0))
            AS dining_votes_log,

        LN(1 + COALESCE(delivery_votes, 0))
            AS delivery_votes_log,

        fulfillment_score

    FROM
        zomato_market_intelligence.silver.fact_restaurant
),

fulfillment_norm AS (

    SELECT
        *,
        
        CASE
            WHEN fulfillment_score IS NOT NULL
            THEN PERCENT_RANK() OVER (
                ORDER BY fulfillment_score
            )
        END AS fulfillment_norm

    FROM base
),

quality AS (

    SELECT
        *,

        CASE
            WHEN dining_rating_norm IS NULL
             AND delivery_rating_norm IS NULL
             AND fulfillment_norm IS NULL
            THEN NULL

            ELSE
                COALESCE(dining_rating_norm, 0) * 0.50
                +
                COALESCE(delivery_rating_norm, 0) * 0.30
                +
                COALESCE(fulfillment_norm, 0) * 0.20
        END AS quality_score

    FROM fulfillment_norm
),

engagement AS (

    SELECT
        *,

        (
            dining_votes_log
            +
            delivery_votes_log
        ) / 2.0 AS engagement_raw

    FROM quality
),

engagement_ranked AS (

    SELECT
        *,

        PERCENT_RANK() OVER (
            ORDER BY engagement_raw
        ) AS engagement_score

    FROM engagement

)

SELECT

    *,

    CASE
        WHEN quality_score >= 0.75
            THEN 'High Quality'
        WHEN quality_score >= 0.50
            THEN 'Medium Quality'
        ELSE 'Low Quality'
    END AS restaurant_quality_band,

    CASE
        WHEN engagement_score >= 0.75
            THEN 'Very High Engagement'
        WHEN engagement_score >= 0.50
            THEN 'High Engagement'
        WHEN engagement_score >= 0.25
            THEN 'Medium Engagement'
        ELSE 'Low Engagement'
    END AS restaurant_engagement_band

FROM engagement_ranked;

-- Validate Restaurant Features
SELECT
    COUNT(*) AS restaurant_count,
    COUNT(DISTINCT restaurant_key) AS unique_restaurants,

    MIN(quality_score) AS min_quality,
    MAX(quality_score) AS max_quality,

    MIN(engagement_score) AS min_engagement,
    MAX(engagement_score) AS max_engagement

FROM
    zomato_market_intelligence.silver.fe_restaurant;

-- Restaurant Popularity Features
-- Features : menu_item_count, avg_item_votes, max_item_votes, total_item_votes, bestseller_count, bestseller_rate, menu_price_avg, menu_price_median

CREATE OR REPLACE TABLE
zomato_market_intelligence.silver.fe_restaurant_menu
USING DELTA
AS

SELECT

    restaurant_key,

    COUNT(DISTINCT menu_item_key)
        AS menu_item_count,

    SUM(
        COALESCE(item_votes, 0)
    )
        AS total_item_votes,

    AVG(
        item_votes
    )
        AS avg_item_votes,

    MAX(
        item_votes
    )
        AS max_item_votes,

    SUM(
        CASE
            WHEN is_best_seller_marked = TRUE
            THEN 1
            ELSE 0
        END
    )
        AS bestseller_count,

    AVG(
        item_price
    )
        AS avg_item_price,

    PERCENTILE_APPROX(
        item_price,
        0.50
    )
        AS median_item_price

FROM
    zomato_market_intelligence.silver.fact_menu_item

GROUP BY
    restaurant_key;

CREATE OR REPLACE TABLE
zomato_market_intelligence.silver.fe_restaurant_menu
USING DELTA
AS

SELECT
    *,

    bestseller_count
    /
    NULLIF(
        menu_item_count,
        0
    )
    AS bestseller_rate

FROM
    zomato_market_intelligence.silver.fe_restaurant_menu;

-- Build Master Restaurant Feature Table
CREATE OR REPLACE TABLE
zomato_market_intelligence.silver.fe_restaurant_master
USING DELTA
AS

SELECT

    r.restaurant_key,
    r.city_key,
    r.locality_key,

    r.dining_rating,
    r.delivery_rating,

    r.dining_votes,
    r.delivery_votes,

    r.fulfillment_score,

    r.restaurant_density,
    r.same_cuisine_count,

    r.market_saturation_score,
    r.expansion_opportunity_score,

    r.dining_rating_norm,
    r.delivery_rating_norm,
    r.rating_completeness,

    r.dining_votes_log,
    r.delivery_votes_log,

    r.quality_score,
    r.engagement_raw,
    r.engagement_score,

    r.restaurant_quality_band,
    r.restaurant_engagement_band,

    m.menu_item_count,
    m.total_item_votes,
    m.avg_item_votes,
    m.max_item_votes,
    m.bestseller_count,
    m.bestseller_rate,

    m.avg_item_price,
    m.median_item_price

FROM
    zomato_market_intelligence.silver.fe_restaurant r

LEFT JOIN
    zomato_market_intelligence.silver.fe_restaurant_menu m

ON
    r.restaurant_key
    =
    m.restaurant_key;

-- Menu item feature table
-- Features : item_votes_log, item_popularity_score, item_price_log, price_vs_market, item_value_efficiency

CREATE OR REPLACE TABLE
zomato_market_intelligence.silver.fe_menu_item
USING DELTA
AS

WITH base AS (

    SELECT

        restaurant_key,
        menu_item_key,
        cuisine_key,
        price_band_key,

        item_price,
        item_votes,

        is_best_seller_marked,

        LN(
            1 + COALESCE(item_votes, 0)
        )
        AS item_votes_log,

        LN(
            1 + COALESCE(item_price, 0)
        )
        AS item_price_log

    FROM
        zomato_market_intelligence.silver.fact_menu_item
),

ranked AS (

    SELECT
        *,

        PERCENT_RANK() OVER (
            ORDER BY item_votes_log
        ) AS item_popularity_score

    FROM base
)

SELECT

    *,

    CASE
        WHEN item_price > 0
        THEN item_votes_log
             /
             NULLIF(
                 item_price_log,
                 0
             )
        ELSE NULL
    END AS item_value_efficiency

FROM ranked;

-- Restaurant Relative Pricing
CREATE OR REPLACE TABLE
zomato_market_intelligence.silver.fe_locality_price_base
USING DELTA
AS

SELECT

    r.locality_key,

    AVG(
        f.item_price
    ) AS locality_avg_price,

    PERCENTILE_APPROX(
        f.item_price,
        0.50
    ) AS locality_median_price

FROM
    zomato_market_intelligence.silver.fact_menu_item f

JOIN
    zomato_market_intelligence.silver.fact_restaurant r

ON
    f.restaurant_key
    =
    r.restaurant_key

WHERE
    f.item_price IS NOT NULL

GROUP BY
    r.locality_key;

CREATE OR REPLACE TABLE
zomato_market_intelligence.silver.fe_restaurant_master
USING DELTA
AS

SELECT

    r.*,

    p.locality_avg_price,

    p.locality_median_price,

    r.avg_item_price
    /
    NULLIF(
        p.locality_avg_price,
        0
    )
    AS restaurant_price_position

FROM
    zomato_market_intelligence.silver.fe_restaurant_master r

LEFT JOIN
    zomato_market_intelligence.silver.fe_locality_price_base p

ON
    r.locality_key
    =
    p.locality_key;

-- Restaurant Feature Validation
SELECT

    COUNT(*) AS rows,

    COUNT(DISTINCT restaurant_key)
        AS restaurants,

    AVG(quality_score)
        AS avg_quality,

    AVG(engagement_score)
        AS avg_engagement,

    AVG(bestseller_rate)
        AS avg_bestseller_rate,

    AVG(restaurant_price_position)
        AS avg_price_position

FROM
    zomato_market_intelligence.silver.fe_restaurant_master;


-- Restaurant Segmentation  features
CREATE OR REPLACE TABLE
zomato_market_intelligence.silver.fe_restaurant_segments
USING DELTA
AS

SELECT

    *,

    CASE

        WHEN quality_score >= 0.75
         AND engagement_score >= 0.75
            THEN 'High Quality — High Engagement'

        WHEN quality_score >= 0.75
         AND engagement_score < 0.50
            THEN 'High Quality — Low Engagement'

        WHEN quality_score < 0.50
         AND engagement_score >= 0.75
            THEN 'Low Quality — High Engagement'

        ELSE 'Mid / Mixed Performance'

    END AS restaurant_performance_segment,

    CASE

        WHEN restaurant_price_position >= 1.25
            THEN 'Premium Relative Pricing'

        WHEN restaurant_price_position <= 0.75
            THEN 'Value Relative Pricing'

        ELSE 'Market-Aligned Pricing'

    END AS restaurant_price_segment

FROM
    zomato_market_intelligence.silver.fe_restaurant_master;


-- Part 2 - Cusine Feature Engineering
-- 11. Restaurant-Cuisine Features
CREATE OR REPLACE TABLE
zomato_market_intelligence.silver.fe_restaurant_cuisine
USING DELTA
AS

SELECT

    b.restaurant_key,
    b.cuisine_key,

    c.cuisine_name,

    r.city_key,
    r.locality_key

FROM
    zomato_market_intelligence.silver.bridge_restaurant_cuisine b

JOIN
    zomato_market_intelligence.silver.dim_cuisine c

ON
    b.cuisine_key
    =
    c.cuisine_key

JOIN
    zomato_market_intelligence.silver.fact_restaurant r

ON
    b.restaurant_key
    =
    r.restaurant_key;

-- Cuisine Diversity By Locality
CREATE OR REPLACE TABLE
zomato_market_intelligence.silver.fe_locality_cuisine
USING DELTA
AS

SELECT

    locality_key,

    COUNT(
        DISTINCT cuisine_key
    )
    AS cuisine_diversity_count,

    COUNT(
        DISTINCT restaurant_key
    )
    AS cuisine_restaurant_count

FROM
    zomato_market_intelligence.silver.fe_restaurant_cuisine

GROUP BY
    locality_key;

-- Cuisine Concentration / HHI
CREATE OR REPLACE TABLE
zomato_market_intelligence.silver.fe_locality_cuisine_hhi
USING DELTA
AS

WITH cuisine_counts AS (

    SELECT

        locality_key,
        cuisine_key,

        COUNT(
            DISTINCT restaurant_key
        )
        AS restaurant_count

    FROM
        zomato_market_intelligence.silver.fe_restaurant_cuisine

    GROUP BY

        locality_key,
        cuisine_key
),

locality_totals AS (

    SELECT

        locality_key,

        SUM(
            restaurant_count
        ) AS total_restaurants

    FROM cuisine_counts

    GROUP BY locality_key
)

SELECT

    c.locality_key,

    SUM(
        POWER(
            c.restaurant_count
            /
            NULLIF(
                l.total_restaurants,
                0
            ),
            2
        )
    )
    AS cuisine_hhi

FROM cuisine_counts c

JOIN locality_totals l

ON
    c.locality_key
    =
    l.locality_key

GROUP BY
    c.locality_key;


-- Cuisine Gap Feature
CREATE OR REPLACE TABLE
zomato_market_intelligence.silver.fe_cuisine_gap
USING DELTA
AS

WITH cuisine_counts AS (

    SELECT

        city_key,
        locality_key,
        cuisine_key,

        COUNT(
            DISTINCT restaurant_key
        )
        AS restaurant_count

    FROM
        zomato_market_intelligence.silver.fe_restaurant_cuisine

    GROUP BY

        city_key,
        locality_key,
        cuisine_key
),

locality_totals AS (

    SELECT

        city_key,
        locality_key,

        SUM(
            restaurant_count
        ) AS locality_restaurant_count

    FROM cuisine_counts

    GROUP BY

        city_key,
        locality_key
),

city_cuisine_totals AS (

    SELECT

        city_key,
        cuisine_key,

        SUM(
            restaurant_count
        ) AS city_cuisine_restaurant_count

    FROM cuisine_counts

    GROUP BY

        city_key,
        cuisine_key
),

city_totals AS (

    SELECT

        city_key,

        SUM(
            city_cuisine_restaurant_count
        )
        AS city_restaurant_count

    FROM city_cuisine_totals

    GROUP BY
        city_key
)

SELECT

    c.city_key,
    c.locality_key,
    c.cuisine_key,

    c.restaurant_count,

    c.restaurant_count
    /
    NULLIF(
        l.locality_restaurant_count,
        0
    )
    AS locality_cuisine_share,

    cc.city_cuisine_restaurant_count
    /
    NULLIF(
        ct.city_restaurant_count,
        0
    )
    AS city_cuisine_share,

    (
        cc.city_cuisine_restaurant_count
        /
        NULLIF(
            ct.city_restaurant_count,
            0
        )
    )
    -
    (
        c.restaurant_count
        /
        NULLIF(
            l.locality_restaurant_count,
            0
        )
    )
    AS cuisine_gap_score

FROM cuisine_counts c

JOIN locality_totals l
ON
    c.city_key = l.city_key
AND
    c.locality_key = l.locality_key

JOIN city_cuisine_totals cc
ON
    c.city_key = cc.city_key
AND
    c.cuisine_key = cc.cuisine_key

JOIN city_totals ct
ON
    c.city_key = ct.city_key;

-- Aggregate Cuisine Opportunity to Locality
CREATE OR REPLACE TABLE
zomato_market_intelligence.silver.fe_locality_cuisine_opportunity
USING DELTA
AS

SELECT

    city_key,
    locality_key,

    MAX(
        CASE
            WHEN cuisine_gap_score > 0
            THEN cuisine_gap_score
            ELSE 0
        END
    )
    AS max_positive_cuisine_gap,

    AVG(
        CASE
            WHEN cuisine_gap_score > 0
            THEN cuisine_gap_score
            ELSE NULL
        END
    )
    AS avg_positive_cuisine_gap,

    COUNT(
        CASE
            WHEN cuisine_gap_score > 0.02
            THEN 1
        END
    )
    AS meaningful_cuisine_gaps

FROM
    zomato_market_intelligence.silver.fe_cuisine_gap

GROUP BY

    city_key,
    locality_key;


-- Part 3 - Locality Pricing features
-- Locality Pricing Feature Table
CREATE OR REPLACE TABLE
zomato_market_intelligence.silver.fe_locality_pricing
USING DELTA
AS

SELECT

    r.city_key,
    r.locality_key,

    AVG(
        m.item_price
    )
    AS avg_item_price,

    PERCENTILE_APPROX(
        m.item_price,
        0.50
    )
    AS median_item_price,

    PERCENTILE_APPROX(
        m.item_price,
        0.75
    )
    AS p75_item_price,

    PERCENTILE_APPROX(
        m.item_price,
        0.90
    )
    AS p90_item_price,

    STDDEV(
        m.item_price
    )
    AS item_price_stddev,

    COUNT(
        DISTINCT m.menu_item_key
    )
    AS menu_item_count

FROM
    zomato_market_intelligence.silver.fact_menu_item m

JOIN
    zomato_market_intelligence.silver.fact_restaurant r

ON
    m.restaurant_key
    =
    r.restaurant_key

WHERE
    m.item_price IS NOT NULL

GROUP BY

    r.city_key,
    r.locality_key;


-- Price Band Diversity
CREATE OR REPLACE TABLE
zomato_market_intelligence.silver.fe_locality_price_diversity
USING DELTA
AS

SELECT

    r.city_key,
    r.locality_key,

    COUNT(
        DISTINCT m.price_band_key
    )
    AS price_band_diversity

FROM
    zomato_market_intelligence.silver.fact_menu_item m

JOIN
    zomato_market_intelligence.silver.fact_restaurant r

ON
    m.restaurant_key = r.restaurant_key

GROUP BY

    r.city_key,
    r.locality_key;

-- Pricing Gap Feature
CREATE OR REPLACE TABLE
zomato_market_intelligence.silver.fe_price_band_gap
USING DELTA
AS

WITH locality_band AS (

    SELECT

        r.city_key,
        r.locality_key,
        m.price_band_key,

        COUNT(*) AS item_count

    FROM fact_menu_item m

    JOIN fact_restaurant r
    ON m.restaurant_key = r.restaurant_key

    GROUP BY

        r.city_key,
        r.locality_key,
        m.price_band_key
),

locality_total AS (

    SELECT

        city_key,
        locality_key,

        SUM(item_count)
        AS total_items

    FROM locality_band

    GROUP BY

        city_key,
        locality_key
),

city_band AS (

    SELECT

        city_key,
        price_band_key,

        SUM(item_count)
        AS city_band_items

    FROM locality_band

    GROUP BY

        city_key,
        price_band_key
),

city_total AS (

    SELECT

        city_key,

        SUM(city_band_items)
        AS city_items

    FROM city_band

    GROUP BY city_key
)

SELECT

    l.city_key,
    l.locality_key,
    l.price_band_key,

    l.item_count
    /
    NULLIF(
        lt.total_items,
        0
    )
    AS locality_band_share,

    cb.city_band_items
    /
    NULLIF(
        ct.city_items,
        0
    )
    AS city_band_share,

    (
        cb.city_band_items
        /
        NULLIF(
            ct.city_items,
            0
        )
    )
    -
    (
        l.item_count
        /
        NULLIF(
            lt.total_items,
            0
        )
    )
    AS pricing_gap_score

FROM locality_band l

JOIN locality_total lt
ON
    l.city_key = lt.city_key
AND
    l.locality_key = lt.locality_key

JOIN city_band cb
ON
    l.city_key = cb.city_key
AND
    l.price_band_key = cb.price_band_key

JOIN city_total ct
ON
    l.city_key = ct.city_key;

CREATE OR REPLACE TABLE
zomato_market_intelligence.silver.fe_locality_pricing_opportunity
USING DELTA
AS

SELECT

    city_key,
    locality_key,

    MAX(
        CASE
            WHEN pricing_gap_score > 0
            THEN pricing_gap_score
            ELSE 0
        END
    )
    AS max_positive_pricing_gap,

    AVG(
        CASE
            WHEN pricing_gap_score > 0
            THEN pricing_gap_score
        END
    )
    AS avg_positive_pricing_gap

FROM
    zomato_market_intelligence.silver.fe_price_band_gap

GROUP BY

    city_key,
    locality_key;


-- Part 4 - Locality Market Features
-- Locality Core Feature Table
CREATE OR REPLACE TABLE
zomato_market_intelligence.silver.fe_locality
USING DELTA
AS

WITH base AS (

    SELECT

        r.city_key,
        r.locality_key,

        COUNT(
            DISTINCT r.restaurant_key
        )
        AS restaurant_count,

        AVG(
            r.quality_score
        )
        AS locality_quality_score,

        AVG(
            r.engagement_score
        )
        AS locality_engagement_score,

        AVG(
            r.bestseller_rate
        )
        AS avg_bestseller_rate

    FROM
        zomato_market_intelligence.silver.fe_restaurant_master r

    GROUP BY

        r.city_key,
        r.locality_key
)

SELECT

    b.*,

    c.cuisine_diversity_count,

    h.cuisine_hhi,

    p.avg_item_price,

    p.median_item_price,

    p.p75_item_price,

    p.p90_item_price,

    p.item_price_stddev,

    p.menu_item_count,

    pd.price_band_diversity,

    co.max_positive_cuisine_gap,

    co.avg_positive_cuisine_gap,

    co.meaningful_cuisine_gaps,

    po.max_positive_pricing_gap,

    po.avg_positive_pricing_gap

FROM base b

LEFT JOIN
    zomato_market_intelligence.silver.fe_locality_cuisine c

ON
    b.locality_key = c.locality_key

LEFT JOIN
    zomato_market_intelligence.silver.fe_locality_cuisine_hhi h

ON
    b.locality_key = h.locality_key

LEFT JOIN
    zomato_market_intelligence.silver.fe_locality_pricing p

ON
    b.locality_key = p.locality_key
AND
    b.city_key = p.city_key

LEFT JOIN
    zomato_market_intelligence.silver.fe_locality_price_diversity pd

ON
    b.locality_key = pd.locality_key
AND
    b.city_key = pd.city_key

LEFT JOIN
    zomato_market_intelligence.silver.fe_locality_cuisine_opportunity co

ON
    b.locality_key = co.locality_key
AND
    b.city_key = co.city_key

LEFT JOIN
    zomato_market_intelligence.silver.fe_locality_pricing_opportunity po

ON
    b.locality_key = po.locality_key
AND
    b.city_key = po.city_key;

-- Locality Saturation Index
CREATE OR REPLACE TABLE
zomato_market_intelligence.silver.fe_locality_saturation
USING DELTA
AS

WITH base AS (

    SELECT

        l.*,

        PERCENT_RANK()
        OVER (
            ORDER BY restaurant_count
        )
        AS restaurant_density_component,

        PERCENT_RANK()
        OVER (
            ORDER BY cuisine_hhi
        )
        AS cuisine_concentration_component

    FROM
        zomato_market_intelligence.silver.fe_locality l
)

SELECT

    *,

    ROUND(

        0.50
        * restaurant_density_component

        +

        0.50
        * cuisine_concentration_component

    , 4)
    AS engineered_saturation_index

FROM base;


-- Part 5 - Market Quality / Engagement
-- Locality Quality Opportunity
CREATE OR REPLACE TABLE
zomato_market_intelligence.silver.fe_locality_opportunity_components
USING DELTA
AS

WITH base AS (

    SELECT

        *,

        PERCENT_RANK()
        OVER (
            ORDER BY locality_quality_score
        )
        AS quality_component,

        PERCENT_RANK()
        OVER (
            ORDER BY locality_engagement_score
        )
        AS engagement_component,

        PERCENT_RANK()
        OVER (
            ORDER BY
                COALESCE(
                    max_positive_cuisine_gap,
                    0
                )
        )
        AS cuisine_component,

        PERCENT_RANK()
        OVER (
            ORDER BY
                COALESCE(
                    max_positive_pricing_gap,
                    0
                )
        )
        AS pricing_component,

        PERCENT_RANK()
        OVER (
            ORDER BY engineered_saturation_index
        )
        AS saturation_component

    FROM
        zomato_market_intelligence.silver.fe_locality_saturation
)

SELECT

    *,

    1.0
    -
    saturation_component
    AS coverage_opportunity_component

FROM base;

-- Final Expansion Opportunity Feature
CREATE OR REPLACE TABLE
zomato_market_intelligence.silver.fe_market_expansion
USING DELTA
AS

SELECT

    city_key,
    locality_key,

    restaurant_count,

    locality_quality_score,
    locality_engagement_score,

    cuisine_diversity_count,
    cuisine_hhi,

    avg_item_price,
    median_item_price,

    price_band_diversity,

    max_positive_cuisine_gap,
    avg_positive_cuisine_gap,

    max_positive_pricing_gap,
    avg_positive_pricing_gap,

    engineered_saturation_index,

    quality_component,
    engagement_component,

    coverage_opportunity_component,

    cuisine_component,
    pricing_component,

    ROUND(

        0.25
        * quality_component

        +

        0.20
        * engagement_component

        +

        0.25
        * coverage_opportunity_component

        +

        0.15
        * cuisine_component

        +

        0.15
        * pricing_component

    , 4)

    AS engineered_expansion_score

FROM
    zomato_market_intelligence.silver.fe_locality_opportunity_components;


-- Expansion Priority Classification
CREATE OR REPLACE TABLE
zomato_market_intelligence.silver.fe_market_expansion
USING DELTA
AS

SELECT

    *,

    CASE

        WHEN engineered_expansion_score >= 0.75
            THEN 'Priority 1 — High Opportunity'

        WHEN engineered_expansion_score >= 0.50
            THEN 'Priority 2 — Moderate Opportunity'

        ELSE 'Priority 3 — Low Opportunity'

    END
    AS expansion_priority

FROM
    zomato_market_intelligence.silver.fe_market_expansion;


-- Confidence / Evidence Score
CREATE OR REPLACE TABLE
zomato_market_intelligence.silver.fe_market_expansion
USING DELTA
AS

SELECT

    *,

    PERCENT_RANK()
    OVER (
        ORDER BY restaurant_count
    )
    AS market_evidence_score

FROM
    zomato_market_intelligence.silver.fe_market_expansion;


-- Final Feature Validation
SELECT

    MIN(quality_component)
        AS min_quality,

    MAX(quality_component)
        AS max_quality,

    MIN(engagement_component)
        AS min_engagement,

    MAX(engagement_component)
        AS max_engagement,

    MIN(coverage_opportunity_component)
        AS min_coverage,

    MAX(coverage_opportunity_component)
        AS max_coverage,

    MIN(engineered_expansion_score)
        AS min_expansion,

    MAX(engineered_expansion_score)
        AS max_expansion

FROM
    zomato_market_intelligence.silver.fe_market_expansion;

-- Feature Null check
SELECT

    COUNT(*) AS total_rows,

    SUM(
        CASE
            WHEN quality_component IS NULL
            THEN 1
            ELSE 0
        END
    ) AS missing_quality,

    SUM(
        CASE
            WHEN engagement_component IS NULL
            THEN 1
            ELSE 0
        END
    ) AS missing_engagement,

    SUM(
        CASE
            WHEN coverage_opportunity_component IS NULL
            THEN 1
            ELSE 0
        END
    ) AS missing_coverage,

    SUM(
        CASE
            WHEN cuisine_component IS NULL
            THEN 1
            ELSE 0
        END
    ) AS missing_cuisine,

    SUM(
        CASE
            WHEN pricing_component IS NULL
            THEN 1
            ELSE 0
        END
    ) AS missing_pricing

FROM
    zomato_market_intelligence.silver.fe_market_expansion;

-- Feature Distribution
SELECT

    expansion_priority,

    COUNT(*) AS locality_count,

    ROUND(
        AVG(engineered_expansion_score),
        4
    ) AS avg_score

FROM
    zomato_market_intelligence.silver.fe_market_expansion

GROUP BY
    expansion_priority

ORDER BY
    avg_score DESC;

-- Top Expansion Opportunities
SELECT

    c.city_name,
    l.locality_name,

    f.restaurant_count,

    f.locality_quality_score,

    f.locality_engagement_score,

    f.cuisine_diversity_count,

    f.max_positive_cuisine_gap,

    f.max_positive_pricing_gap,

    f.engineered_saturation_index,

    f.engineered_expansion_score,

    f.expansion_priority,

    f.market_evidence_score

FROM
    zomato_market_intelligence.silver.fe_market_expansion f

JOIN
    zomato_market_intelligence.silver.dim_city c

ON
    f.city_key = c.city_key

JOIN
    zomato_market_intelligence.silver.dim_locality l

ON
    f.locality_key = l.locality_key

ORDER BY
    f.engineered_expansion_score DESC

LIMIT 20;

-- Bottom Expansion Opportunities
SELECT

    c.city_name,
    l.locality_name,

    f.restaurant_count,

    f.engineered_saturation_index,

    f.engineered_expansion_score,

    f.expansion_priority,

    f.market_evidence_score

FROM
    zomato_market_intelligence.silver.fe_market_expansion f

JOIN
    zomato_market_intelligence.silver.dim_city c
    ON f.city_key = c.city_key

JOIN
    zomato_market_intelligence.silver.dim_locality l
    ON f.locality_key = l.locality_key

ORDER BY
    f.engineered_expansion_score ASC

LIMIT 20;