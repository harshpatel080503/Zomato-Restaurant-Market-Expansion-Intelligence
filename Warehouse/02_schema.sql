-- We are Building Three layer Schema - Bronze Silver Gold

-- BRONZE
CREATE SCHEMA IF NOT EXISTS bronze
COMMENT 'RAW and staging data for the Zomato Restaurant Market Expansion Intelligence';

-- SILVER
CREATE SCHEMA IF NOT EXISTS silver
COMMENT 'Cleaned dimensional and fact warehouse model';

-- GOLD
CREATE SCHEMA IF NOT EXISTS gold
COMMENT 'Business-ready analytical views for BI and decision intelligence';


-- VERIFY
SHOW SCHEMAS; -- EXPECTED - bronze silver gold