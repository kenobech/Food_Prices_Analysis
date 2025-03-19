-- WORLD FOOD PRICES ANALYSIS

-- Select the Database to use

USE Food_Prices_Kenya;

-- Select the Table

SELECT name AS TableName 
FROM sys.tables 
ORDER BY name;

-- Highlight the table structure

EXEC sp_help wfp_food_prices_ken;

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'wfp_food_prices_ken';

-- Number of Rows and Columns
SELECT *
FROM wfp_food_prices_ken;

--This dataset has 10766 rows and 14 columns.

-- Check for Missing Values

SELECT *
FROM wfp_food_prices_ken
WHERE value IS NULL;

-- Alternatively
SELECT COUNT (*)
 AS Missing_Values
FROM wfp_food_prices_ken
WHERE value IS NULL OR value_usd IS NULL OR date IS NULL;

---There are no missing values

--Checking for Duplicate Values

SELECT *, COUNT(*) 
FROM wfp_food_prices_ken 
GROUP BY date, adm1_name,adm2_name, loc_market_name,geo_lat, geo_lon,item_type,item_name,item_unit,item_price_flag,item_price_type, currency,value, value_usd
HAVING COUNT(*) > 1;

-- Create a Temp Table for a cleaned dataset
IF OBJECT_ID('tempdb..#Cleaned_Food_Prices') IS NOT NULL
    DROP TABLE #Cleaned_Food_Prices;
CREATE TABLE #Cleaned_Food_Prices ( 
    date DATE, 
    adm1_name NVARCHAR(255), 
    adm2_name NVARCHAR (255), 
    loc_market_name NVARCHAR (255), 
    geo_lat FLOAT, 
    geo_lon FLOAT, 
    item_type NVARCHAR (255), 
    item_name NVARCHAR (255), 
    item_unit NVARCHAR (255), 
    item_price_flag NVARCHAR (255), 
    item_price_type NVARCHAR (255), 
    currency NVARCHAR (255), 
    value DECIMAL (18,2), 
    value_usd DECIMAL (18,2)
);

-- Insert Data into #Cleaned_Food_Prices

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

-- Create a Temporary Table for Price Analysis
IF OBJECT_ID('tempdb..#Temp_Price_Analysis') IS NOT NULL
    DROP TABLE #Temp_Price_Analysis;

CREATE TABLE #Temp_Price_Analysis (
     month DATE,
	 loc_market_name VARCHAR (255),
	 item_name VARCHAR (255),
	 Avg_value DECIMAL (18,2),
	 Avg_value_usd DECIMAL (18,2),
	 prev_avg_value DECIMAL (18,2),
	 value_change_pct DECIMAL (18,2)
);

-- Insert Data into #Temp_Price_Analysis

INSERT INTO #Temp_Price_Analysis
SELECT 
    DATEADD(MONTH, DATEDIFF(MONTH, 0, date), 0) AS month, 
    loc_market_name, 
    item_name, 
    AVG(value) AS avg_value, 
    AVG(value_usd) AS avg_usdvalue,
    LAG(AVG(value), 1) OVER (PARTITION BY loc_market_name, item_name ORDER BY DATEADD(MONTH, DATEDIFF(MONTH, 0, date), 0)) AS prev_avg_value,
    (AVG(value) - LAG(AVG(value), 1) OVER (PARTITION BY loc_market_name, item_name ORDER BY DATEADD(MONTH, DATEDIFF(MONTH, 0, date), 0))) / LAG(AVG(value), 1) OVER (PARTITION BY loc_market_name, item_name ORDER BY DATEADD(MONTH, DATEDIFF(MONTH, 0, date), 0)) * 100 AS value_change_pct
FROM #Cleaned_Food_Prices
GROUP BY DATEADD(MONTH, DATEDIFF(MONTH, 0, date), 0), loc_market_name, item_name;

-- Count of Commodities
SELECT item_name, COUNT(DISTINCT item_name)
      AS Count_of_Item_Name
FROM #Cleaned_Food_Prices
GROUP BY item_name;

-- Count of Cpmmodity Type
SELECT item_type, COUNT(DISTINCT item_type)
      AS Count_of_Item_type
FROM #Cleaned_Food_Prices
GROUP BY item_type;

-- Count of Price Type
SELECT item_price_type, COUNT(DISTINCT item_price_type)
      AS Count_of_Price_type
FROM #Cleaned_Food_Prices
GROUP BY item_price_type;

--Market Data
SELECT loc_market_name, COUNT(loc_market_name)
      AS Count_of_loc_market_name
FROM #Cleaned_Food_Prices
GROUP BY loc_market_name;


-- Total Records
SELECT COUNT(*) AS Total_Records,
COUNT(DISTINCT item_name) AS Count_of_Item_Name,
	   COUNT(DISTINCT item_type) AS Count_of_Item_Type,
	   COUNT(DISTINCT item_price_type) AS Count_of_Item_Price_Type,
	   COUNT(loc_market_name) AS Count_of_loc_market_name
FROM #Cleaned_Food_Prices;

-- Monthly Average Prices
SELECT date, ROUND(AVG(value),2)
      AS Avg_Price
FROM #Cleaned_Food_Prices
GROUP BY date
ORDER BY date;

-- Top 5 Monthly Average Prices
SELECT TOP 5 date, ROUND(AVG(value),2)
       AS Avg_Price
FROM #Cleaned_Food_Prices
GROUP BY date
ORDER BY Avg_Price DESC;

--Yearly Average Prices
SELECT 
    YEAR(date) AS year, 
    item_name, 
    loc_market_name, 
    AVG(value) AS avg_price, 
    AVG(value_usd) AS avg_usdprice
FROM #Cleaned_Food_Prices
GROUP BY YEAR(date), item_name, loc_market_name
ORDER BY year, item_name, loc_market_name;

--Highest Price
SELECT MAX(value)
       AS Max_Value
FROM #Cleaned_Food_Prices;

--Lowest Price
SELECT MIN(value)
       AS Min_Value
FROM #Cleaned_Food_Prices;

-- The most expensive commodities
SELECT TOP 5 Value, item_name
FROM #Cleaned_Food_Prices
ORDER BY value DESC;

--Average Prices of Different Markets
SELECT loc_market_name, ROUND(AVG(value),2)
      AS Avg_Price
FROM #Cleaned_Food_Prices
GROUP BY loc_market_name
ORDER BY Avg_Price DESC;

-- Top 10 Markets with the Highest Food Prices

SELECT TOP 10 loc_market_name,item_name, ROUND(AVG(value),2) AS Avg_Value
FROM #Cleaned_Food_Prices
GROUP BY loc_market_name, item_name
ORDER BY Avg_Value DESC;

-- The Average Price per Item Price Type
SELECT item_price_type, ROUND(AVG(value),2) AS Avg_Price
FROM #Cleaned_Food_Prices
GROUP BY item_price_type
ORDER BY Avg_Price DESC;

-- Create an Index for Faster Querries

CREATE INDEX idx_market_commodity ON #Cleaned_Food_Prices (loc_market_name, item_name);
CREATE INDEX idx_date ON #Cleaned_Food_Prices (date);
CREATE INDEX idx_value ON #Cleaned_Food_Prices (value);
CREATE INDEX idx_commodity ON #Cleaned_Food_Prices (item_name);
CREATE CLUSTERED INDEX idx_date_clustered ON #Cleaned_Food_Prices (date);


--Analyze Price Trends
SELECT 
    loc_market_name, item_name, date, value, 
    LAG(value, 1) OVER (PARTITION BY loc_market_name, item_name ORDER BY date) AS previous_value, 
    value - LAG(value, 1) OVER (PARTITION BY loc_market_name, item_name ORDER BY date) AS value_change
FROM #Cleaned_Food_Prices;

-- Create a Stored Procedure for Market Data
IF OBJECT_ID('GetMarketData', 'P') IS NOT NULL
    DROP PROCEDURE GetMarketData;
GO
CREATE PROCEDURE GetMarketData @item_name NVARCHAR(255)
AS
BEGIN
    SELECT loc_market_name, value, value_usd, date
    FROM #Cleaned_Food_Prices
    WHERE item_name = @item_name
    ORDER BY date DESC;
END;
GO

-- Create a Stored Procedure for Monthly Value Aggregation
IF OBJECT_ID('MonthlyValueAggregation', 'P') IS NOT NULL
    DROP PROCEDURE MonthlyValueAggregation;
GO
CREATE PROCEDURE MonthlyValueAggregation
AS
BEGIN
    CREATE TABLE #Monthly_Aggregates (
        month DATE,
        item_name NVARCHAR(255),
        loc_market_name NVARCHAR(255),
        avg_value DECIMAL(18,2),
        avg_valueusd DECIMAL(18,2)
    );
INSERT INTO #Monthly_Aggregates
    SELECT DATEADD(MONTH, DATEDIFF(MONTH, 0, date), 0) AS month, 
           item_name, loc_market_name, 
           AVG(value) AS avg_value, 
           AVG(value_usd) AS avg_value_usd
    FROM #Cleaned_Food_Prices
    GROUP BY DATEADD(MONTH, DATEDIFF(MONTH, 0, date), 0), item_name, loc_market_name;
END;
GO

-- Create a Stored Procedure to Get Top Price Increases
IF OBJECT_ID('GetTopPriceIncreases', 'P') IS NOT NULL
    DROP PROCEDURE GetTopPriceIncreases;
GO
CREATE PROCEDURE GetTopPriceIncreases
AS
BEGIN
    SELECT TOP 10 loc_market_name, item_name, price_change_pct
    FROM #Price_Analysis
    ORDER BY price_change_pct DESC;
END;
GO

-- Calculate the Price Volatility
IF OBJECT_ID('CalculateVolatility', 'IF') IS NOT NULL
    DROP FUNCTION CalculateVolatility;
GO
CREATE FUNCTION CalculateVolatility(@item_name NVARCHAR(255))
RETURNS TABLE
AS
RETURN (
    WITH ValueStats AS (
        SELECT loc_market_name, value
        FROM wfp_food_prices_ken
        WHERE item_name = @item_name
    )
    SELECT loc_market_name, STDEV(value) AS volatility
    FROM ValueStats
    GROUP BY loc_market_name
);
GO
-- Most Volatile Commodity Prices

SELECT item_name, ROUND(MAX(value),2)- ROUND(MIN(value),2)
       AS Price_Difference
FROM #Cleaned_Food_Prices
GROUP BY item_name
ORDER BY Price_Difference DESC;

-- Call the function
SELECT * FROM dbo.CalculateVolatility('Maize');
SELECT * FROM dbo.CalculateVolatility('Beans');
SELECT * FROM dbo.CalculateVolatility('Cowpeas');









