-- WORLD FOOD PRICES ANALYSIS

-- Step 1: Select the Database to use
USE Food_Prices_Kenya;

-- Step 2: Inspect the Table Structure
SELECT name AS TableName 
FROM sys.tables 
ORDER BY name;

EXEC sp_help wfp_food_prices_ken;

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'wfp_food_prices_ken';

-- Step 3: Check for Missing Values
SELECT COUNT(*) AS Missing_Values
FROM wfp_food_prices_ken
WHERE value IS NULL OR value_usd IS NULL OR date IS NULL;

-- Step 4: Check for Duplicate Records
SELECT 
    date, 
    adm1_name, 
    adm2_name, 
    loc_market_name, 
    item_name, 
    COUNT(*) AS DuplicateCount
FROM wfp_food_prices_ken
GROUP BY 
    date, 
    adm1_name, 
    adm2_name, 
    loc_market_name, 
    item_name
HAVING COUNT(*) > 1;

-- Step 5: Create a Cleaned Dataset
IF OBJECT_ID('tempdb..#Cleaned_Food_Prices') IS NOT NULL
    DROP TABLE #Cleaned_Food_Prices;

CREATE TABLE #Cleaned_Food_Prices (
    date DATE, 
    adm1_name NVARCHAR(255), 
    adm2_name NVARCHAR(255), 
    loc_market_name NVARCHAR(255), 
    geo_lat FLOAT, 
    geo_lon FLOAT, 
    item_type NVARCHAR(255), 
    item_name NVARCHAR(255), 
    item_unit NVARCHAR(255), 
    item_price_flag NVARCHAR(255), 
    item_price_type NVARCHAR(255), 
    currency NVARCHAR(255), 
    value DECIMAL(18,2), 
    value_usd DECIMAL(18,2)
);

INSERT INTO #Cleaned_Food_Prices
SELECT 
    CAST(date AS DATE), 
    adm1_name, 
    adm2_name, 
    loc_market_name, 
    CAST(geo_lat AS FLOAT), 
    CAST(geo_lon AS FLOAT), 
    item_type, 
    item_name, 
    item_unit, 
    item_price_flag, 
    item_price_type, 
    currency,
    CAST(value AS DECIMAL(18,2)), 
    CAST(value_usd AS DECIMAL(18,2))
FROM wfp_food_prices_ken;

-- Step 6: Analyze Monthly Price Trends
WITH MonthlyTrends AS (
    SELECT 
        CONVERT(DATE, DATEADD(MONTH, DATEDIFF(MONTH, 0, date), 0)) AS month, -- Extract the month
        item_name, -- Commodity name
        CAST(ROUND(AVG(value),2) AS DECIMAL (10,2)) AS avg_price -- Properly round the average price to 2 decimal places
    FROM 
        #Cleaned_Food_Prices
    GROUP BY 
        DATEADD(MONTH, DATEDIFF(MONTH, 0, date), 0), 
        item_name
)
SELECT *
FROM MonthlyTrends
ORDER BY 
    month, 
    item_name;

-- Step 7: Regional Price Comparisons
WITH RegionalComparisons AS (
    SELECT 
        adm1_name AS region, 
        item_name, 
        CAST(ROUND(AVG(value), 2) AS DECIMAL (10,2)) AS avg_price -- Properly round the average price
    FROM 
        #Cleaned_Food_Prices
    GROUP BY 
        adm1_name, 
        item_name
)
SELECT *
FROM RegionalComparisons
ORDER BY 
    region, 
    avg_price DESC;

-- Step 8: Commodity Volatility Analysis
WITH Volatility AS (
    SELECT 
        item_name, 
        ROUND(STDEV(value), 2) AS price_volatility, -- Calculate price volatility
        CAST(ROUND(AVG(value), 2) AS DECIMAL (10,2)) AS avg_price -- Properly round the average price
    FROM 
        #Cleaned_Food_Prices
    GROUP BY 
        item_name
)
SELECT *
FROM Volatility
ORDER BY 
    price_volatility DESC;

-- Step 9: Market Analysis
WITH MarketAnalysis AS (
    SELECT 
        loc_market_name AS market, 
        item_name, 
        CAST(ROUND(AVG(value), 2) AS DECIMAL (10,2)) AS avg_price -- Properly round the average price
    FROM 
        #Cleaned_Food_Prices
    GROUP BY 
        loc_market_name, 
        item_name
)
SELECT *
FROM MarketAnalysis
ORDER BY 
    avg_price DESC;

-- Step 10: Yearly Average Prices
WITH YearlyAverages AS (
    SELECT 
        YEAR(date) AS year, 
        item_name, 
        loc_market_name, 
        CAST(ROUND(AVG(value), 2) AS DECIMAL (10,2)) AS avg_price, -- Properly round the average price
        CAST(ROUND(AVG(value_usd), 2) AS DECIMAL (10,2)) AS avg_usd_price -- Properly round the average USD price
    FROM 
        #Cleaned_Food_Prices
    GROUP BY 
        YEAR(date), 
        item_name, 
        loc_market_name
)
SELECT *
FROM YearlyAverages
ORDER BY 
    year, 
    item_name, 
    loc_market_name;

-- Step 11: Most Expensive Commodities
SELECT TOP 5 
    item_name, 
    MAX(value) AS Max_Price -- Find the maximum price
FROM 
    #Cleaned_Food_Prices
GROUP BY 
    item_name
ORDER BY 
    Max_Price DESC;

-- Step 12: Cheapest Commodities
SELECT TOP 5 
    item_name, 
    MIN(value) AS Min_Price -- Find the minimum price
FROM 
    #Cleaned_Food_Prices
GROUP BY 
    item_name
ORDER BY 
    Min_Price ASC;

-- Step 13: Create Indexes for Faster Queries
CREATE INDEX idx_market_commodity ON #Cleaned_Food_Prices (loc_market_name, item_name);
CREATE INDEX idx_date ON #Cleaned_Food_Prices (date);
CREATE INDEX idx_value ON #Cleaned_Food_Prices (value);

-- Step 14: Stored Procedure for Market Data
IF OBJECT_ID('GetMarketData', 'P') IS NOT NULL
    DROP PROCEDURE GetMarketData;

CREATE PROCEDURE GetMarketData @item_name NVARCHAR(255)
AS
BEGIN
    SELECT 
        loc_market_name, 
        value, 
        value_usd, 
        date
    FROM 
        #Cleaned_Food_Prices
    WHERE 
        item_name = @item_name
    ORDER BY 
        date DESC;
END;

-- Step 15: Stored Procedure for Monthly Aggregates
IF OBJECT_ID('MonthlyValueAggregation', 'P') IS NOT NULL
    DROP PROCEDURE MonthlyValueAggregation;

CREATE PROCEDURE MonthlyValueAggregation
AS
BEGIN
    SELECT 
        DATEADD(MONTH, DATEDIFF(MONTH, 0, date), 0) AS month, 
        item_name, 
        loc_market_name, 
        ROUND(AVG(value), 2) AS avg_value, 
        ROUND(AVG(value_usd), 2) AS avg_value_usd
    FROM 
        #Cleaned_Food_Prices
    GROUP BY 
        DATEADD(MONTH, DATEDIFF(MONTH, 0, date), 0), 
        item_name, 
        loc_market_name;
END;

-- Step 16: Visualization Datasets
-- Monthly Price Trends
SELECT 
    DATEADD(MONTH, DATEDIFF(MONTH, 0, date), 0) AS Month, -- Extract only the month
    item_name, -- Commodity name
    ROUND(AVG(value), 2) AS avg_price -- Properly round the average price to 2 decimal places
FROM 
    #Cleaned_Food_Prices
GROUP BY 
    DATEADD(MONTH, DATEDIFF(MONTH, 0, date), 0), 
    item_name
ORDER BY 
    Month, 
    item_name;

-- Month with the highest prices
WITH MonthlyAverages AS (
    SELECT 
        YEAR(date) AS year, -- Extract the year
        DATENAME(MONTH, date) AS month_name, -- Extract the month name
        MONTH(date) AS month_number, -- Extract the month number for ordering
        ROUND(AVG(value), 2) AS avg_price -- Calculate the average price for the month, rounded to 2 decimal places
    FROM 
        #Cleaned_Food_Prices
    GROUP BY 
        YEAR(date), 
        MONTH(date), 
        DATENAME(MONTH, date)
),
HighestPrices AS (
    SELECT 
        year, 
        MAX(avg_price) AS max_price -- Find the maximum average price for each year
    FROM 
        MonthlyAverages
    GROUP BY 
        year
)
SELECT 
    ma.year, 
    ma.month_name, 
    ma.avg_price AS highest_price
FROM 
    MonthlyAverages ma
JOIN 
    HighestPrices hp
ON 
    ma.year = hp.year AND ma.avg_price = hp.max_price
ORDER BY 
    ma.year, 
    ma.month_number;

-- Months with the lowest prices across the years
WITH MonthlyAverages AS (
    SELECT 
        YEAR(date) AS year, -- Extract the year
        DATENAME(MONTH, date) AS month_name, -- Extract the month name
        MONTH(date) AS month_number, -- Extract the month number for ordering
        ROUND(AVG(value), 2) AS avg_price -- Calculate the average price for the month, rounded to 2 decimal places
    FROM 
        #Cleaned_Food_Prices
    GROUP BY 
        YEAR(date), 
        MONTH(date), 
        DATENAME(MONTH, date)
),
LowestPrices AS (
    SELECT 
        year, 
        MIN(avg_price) AS min_price -- Find the minimum average price for each year
    FROM 
        MonthlyAverages
    GROUP BY 
        year
)
SELECT 
    ma.year, 
    ma.month_name, 
    ma.avg_price AS lowest_price
FROM 
    MonthlyAverages ma
JOIN 
    LowestPrices lp
ON 
    ma.year = lp.year AND ma.avg_price = lp.min_price
ORDER BY 
    ma.year, 
    ma.month_number;

-- Yearly Trends
SELECT 
    YEAR(date) AS year, -- Extract the year
    DATENAME(MONTH, date) AS month_name, -- Extract the month name
    item_name, -- Commodity name
    ROUND(AVG(value), 2) AS avg_price, -- Average price for the month
    MIN(value) AS min_price, -- Minimum price for the month
    MAX(value) AS max_price, -- Maximum price for the month
    ROUND(STDEV(value), 2) AS price_volatility -- Price volatility (standard deviation)
FROM 
    #Cleaned_Food_Prices
GROUP BY 
    YEAR(date), 
    DATENAME(MONTH, date), 
    MONTH(date), 
    item_name
ORDER BY 
    year, 
    item_name;

-- Dataset for Regional Price Comparisons
SELECT 
    adm1_name AS region, 
    item_name, 
    ROUND(AVG(value), 2) AS avg_price
FROM 
    #Cleaned_Food_Prices
GROUP BY 
    adm1_name, 
    item_name
ORDER BY 
    region, 
    avg_price DESC;

-- Regions with high prices
WITH RegionalAverages AS (
    SELECT 
        YEAR(date) AS year, -- Extract the year
        adm1_name, -- Administrative level 1 (e.g., region)
        adm2_name, -- Administrative level 2 (e.g., sub-region)
        loc_market_name, -- Market name
        ROUND(AVG(value), 2) AS avg_price -- Calculate the average price for the region, rounded to 2 decimal places
    FROM 
        #Cleaned_Food_Prices
    GROUP BY 
        YEAR(date), 
        adm1_name, 
        adm2_name, 
        loc_market_name
),
HighestPrices AS (
    SELECT 
        year, 
        MAX(avg_price) AS max_price -- Find the maximum average price for each year
    FROM 
        RegionalAverages
    GROUP BY 
        year
)
SELECT 
    ra.year, 
    ra.adm1_name, 
    ra.adm2_name, 
    ra.loc_market_name,
    ra.avg_price AS highest_price
FROM 
    RegionalAverages ra
JOIN 
    HighestPrices hp
ON 
    ra.year = hp.year AND ra.avg_price = hp.max_price
ORDER BY 
    ra.year, 
    ra.adm1_name, 
    ra.adm2_name, 
    ra.loc_market_name;

-- Regions with the lowest prices
WITH RegionalAverages AS (
    SELECT 
        YEAR(date) AS year, -- Extract the year
        adm1_name, 
        adm2_name, 
        loc_market_name, 
        ROUND(AVG(value), 2) AS avg_price -- Calculate the average price for the region, rounded to 2 decimal places
    FROM 
        #Cleaned_Food_Prices
    GROUP BY 
        YEAR(date), 
        adm1_name, 
        adm2_name, 
        loc_market_name
),
LowestPrices AS (
    SELECT 
        year, 
        MIN(avg_price) AS min_price -- Find the minimum average price for each year
    FROM 
        RegionalAverages
    GROUP BY 
        year
)
SELECT 
    ra.year, 
    ra.adm1_name, 
    ra.adm2_name, 
    ra.loc_market_name,
    ra.avg_price AS lowest_price
FROM 
    RegionalAverages ra
JOIN 
    LowestPrices lp
ON 
    ra.year = lp.year AND ra.avg_price = lp.min_price
ORDER BY 
    ra.year, 
    ra.adm1_name, 
    ra.adm2_name, 
    ra.loc_market_name;

-- Dataset for Market Analysis
SELECT 
    loc_market_name AS market, 
    item_name, 
    ROUND(AVG(value), 2) AS avg_price
FROM 
    #Cleaned_Food_Prices
GROUP BY 
    loc_market_name, 
    item_name
ORDER BY 
    avg_price DESC;