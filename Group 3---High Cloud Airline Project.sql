USE airlines;
-- =========================================================
-- CREATE TABLEAU-EQUIVALENT VIEW
-- =========================================================

DROP VIEW IF EXISTS tableau_data;

CREATE VIEW tableau_data AS
SELECT
    *,

    -- Tableau Date = MAKEDATE([Year],[Month],[Day])
    STR_TO_DATE(
        CONCAT(Year,'-',`Month (#)`,'-',Day),
        '%Y-%m-%d'
    ) AS Date_Field,

    -- Tableau load_factor = [# Transported Passengers]/[# Available Seats]
    CAST(`# Transported Passengers` AS DECIMAL(18,4)) /
    NULLIF(CAST(`# Available Seats` AS DECIMAL(18,4)),0) AS load_factor,

    -- Tableau Flight count = 1
    1 AS Flight_Count

FROM maindata;



-- =========================================================
-- KPI 1 : TOTAL AIRLINES
-- Tableau = CNTD(Origin Airport Code)
-- Expected = 1406
-- =========================================================

SELECT
    COUNT(distinct `Origin Airport Code`) AS Total_Airlines
FROM maindata;



-- =========================================================
-- KPI 2 : TOTAL PASSENGERS
-- Tableau = SUM(# Transported Passengers)
-- Expected = 187 M
-- =========================================================

SELECT
    CONCAT(
        ROUND(
            SUM(CAST(`# Transported Passengers` AS UNSIGNED))/1000000,
            0
        ),
        'M'
    ) AS Total_Passengers
FROM maindata;



-- =========================================================
-- KPI 3 : TOTAL AVAILABLE SEATS
-- Tableau = CNTD(# Available Seats)
-- Expected = 7348
-- =========================================================

SELECT
     count(distinct `# Available Seats`) AS Total_Available_Seats
FROM maindata;



-- =========================================================
-- KPI 4 : TOTAL DISTANCE
-- Tableau = SUM(Distance)
-- Expected = 82M
-- =========================================================

SELECT
    CONCAT(
        ROUND(
            SUM(CAST(Distance AS UNSIGNED))/1000000,
            0
        ),
        'M'
    ) AS Total_Distance
FROM maindata;



-- =========================================================
-- CHART 1 : LOAD FACTOR BASED ON CARRIER NAME
-- Tableau = SUM(load_factor)
-- =========================================================


SELECT `Carrier Name`, 
ROUND( SUM(load_factor) * 100, 2 ) AS Load_Factor_Percentage
 FROM tableau_data 
 GROUP BY `Carrier Name` 
 ORDER BY Load_Factor_Percentage desc;


-- =========================================================
-- CHART 2 : TOP 10 CARRIERS BY PASSENGER PREFERENCE
-- Tableau = CNT(# Transported Passengers)
-- =========================================================

SELECT
    `Carrier Name`,
    COUNT(`# Transported Passengers`) AS Passenger_Count
FROM maindata
GROUP BY `Carrier Name`
ORDER BY Passenger_Count DESC
LIMIT 10;



-- =========================================================
-- CHART 3 : TOP 5 ROUTES BY NUMBER OF FLIGHTS
-- Tableau = SUM(# Departures Performed)
-- =========================================================

SELECT
    `From - To City`,
    SUM(CAST(`# Departures Performed` AS UNSIGNED)) AS Total_Flights
FROM maindata
GROUP BY `From - To City`
ORDER BY Total_Flights DESC
LIMIT 5;



-- =========================================================
-- CHART 4 : DISTANCE GROUP FLIGHT COUNT
-- Tableau = CNTD(Flight Count)
-- =========================================================

SELECT
    dg.DistanceInterval,
    COUNT(*) AS Flight_Count
FROM maindata md
JOIN distancegroups dg
    ON CAST(md.`%Distance Group ID` AS UNSIGNED) = dg.DistanceGroupID
GROUP BY dg.DistanceInterval
ORDER BY Flight_Count DESC
LIMIT 10;



-- =========================================================
-- CHART 5 : WEEKEND VS WEEKDAY LOAD FACTOR
-- Tableau = SUM(load_factor)
-- =========================================================

SELECT
    CASE
        WHEN DAYOFWEEK(Date_Field) IN (1,7)
            THEN 'Weekend'
        ELSE 'Weekday'
    END AS Day_Type,

    ROUND(
        SUM(load_factor) * 100,
        2
    ) AS Load_Factor

FROM tableau_data
GROUP BY Day_Type;



-- =========================================================
-- CHART 6 : MONTH WISE LOAD FACTOR
-- Tableau = SUM(load_factor)
-- =========================================================

SELECT
    MONTHNAME(Date_Field) AS Month_Name,

    ROUND(
        SUM(load_factor) * 100,
        2
    ) AS Load_Factor

FROM tableau_data
GROUP BY
    MONTH(Date_Field),
    MONTHNAME(Date_Field)

ORDER BY MONTH(Date_Field);



-- =========================================================
-- CHART 7 : QUARTER WISE LOAD FACTOR
-- Tableau Quarter = 'Q'+DATEPART(quarter,[Date])
-- =========================================================

SELECT
    CONCAT('Q', QUARTER(Date_Field)) AS Quarter_Name,

    ROUND(
        SUM(load_factor) * 100,
        3
    ) AS Load_Factor

FROM tableau_data
GROUP BY QUARTER(Date_Field)
ORDER BY QUARTER(Date_Field);



-- =========================================================
-- CHART 8 : YEAR WISE LOAD FACTOR
-- Tableau = SUM(load_factor)
-- =========================================================

SELECT
    YEAR(Date_Field) AS Year,

    ROUND(
        SUM(load_factor) * 100,
        2
    ) AS Load_Factor

FROM tableau_data
GROUP BY YEAR(Date_Field)
ORDER BY YEAR(Date_Field);



-- =========================================================
-- FILTER : YEAR
-- =========================================================

SELECT DISTINCT
    YEAR(Date_Field) AS Year
FROM tableau_data
ORDER BY Year;



-- =========================================================
-- FILTER : QUARTER
-- =========================================================

SELECT DISTINCT
    CONCAT('Q', QUARTER(Date_Field)) AS Quarter_Name
FROM tableau_data
ORDER BY Quarter_Name;



-- =========================================================
-- FILTER : MONTH
-- =========================================================

SELECT DISTINCT
    MONTHNAME(Date_Field) AS Month_Name
FROM tableau_data
ORDER BY MONTH(Date_Field);



-- =========================================================
-- FILTER : WEEKDAY NAME
-- =========================================================

SELECT DISTINCT
    DAYNAME(Date_Field) AS Weekday_Name
FROM tableau_data
ORDER BY DAYOFWEEK(Date_Field);



-- =========================================================
-- FINANCIAL QUARTER
-- Tableau:
-- Apr-Jun = Q1
-- Jul-Sep = Q2
-- Oct-Dec = Q3
-- Jan-Mar = Q4
-- =========================================================

SELECT
    Date_Field,

    CASE
        WHEN MONTH(Date_Field) BETWEEN 4 AND 6 THEN 'Q1'
        WHEN MONTH(Date_Field) BETWEEN 7 AND 9 THEN 'Q2'
        WHEN MONTH(Date_Field) BETWEEN 10 AND 12 THEN 'Q3'
        ELSE 'Q4'
    END AS Financial_Quarter

FROM tableau_data;



-- =========================================================
-- FINANCIAL MONTH
-- Tableau:
-- Apr=1 ... Mar=12
-- =========================================================

SELECT
    Date_Field,

    CASE
        WHEN MONTH(Date_Field) >= 4
            THEN MONTH(Date_Field) - 3
        ELSE MONTH(Date_Field) + 9
    END AS Financial_Month

FROM tableau_data;