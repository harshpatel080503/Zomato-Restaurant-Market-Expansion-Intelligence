CREATE CATALOG IF NOT EXISTS zomato_market_intelligence;

USE CATALOG zomato_market_intelligence;

-- Verify
SELECT CURRENT_CATALOG(); -- Expected = zomato_market_intelligence