CREATE DATABASE zomato_project;
USE zomato_project;

DROP TABLE IF EXISTS zomato;

CREATE TABLE zomato (
    RestaurantID BIGINT PRIMARY KEY,
    RestaurantName VARCHAR(255),
    CountryCode INT,
    CountryName VARCHAR(100),
    City VARCHAR(120),
    Address TEXT,
    Locality VARCHAR(255),
    Longitude DECIMAL(12,6),
    Latitude DECIMAL(12,6),
    Cuisines VARCHAR(500),
    Currency VARCHAR(100),
    Has_Table_booking VARCHAR(10),
    Has_Online_delivery VARCHAR(10),
    Is_delivering_now VARCHAR(10),
    Price_range INT,
    PriceLabel VARCHAR(50),
    Votes INT,
    Average_Cost_for_two INT,
    Rating DECIMAL(3,1),
    RatingCategory VARCHAR(50),
    Datekey_Opening VARCHAR(20),
    Opening_Date_Fixed DATE,
    `Year` INT,
    `Month` INT,
    MonthName VARCHAR(20),
    MonthFull VARCHAR(20),
    `Quarter` VARCHAR(5),
    YearMonth VARCHAR(20),
    WeekdayNo INT,
    WeekdayName VARCHAR(20),
    FinMonth VARCHAR(5),
    FinQuarter VARCHAR(5)
);

SHOW VARIABLES LIKE 'secure_file_priv';

SET GLOBAL local_infile = 1;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/zomato_resto.csv'
INTO TABLE zomato
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
SHOW WARNINGS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/zomato_resto.csv'
INTO TABLE zomato
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT COUNT(*) FROM zomato;

CREATE OR REPLACE VIEW country_map AS
SELECT
    CountryCode,
    CountryName,
    COUNT(*) AS No_of_Restaurants,
    ROUND(AVG(Rating),2) AS Avg_Rating,
    ROUND(AVG(Average_Cost_for_two),0) AS Avg_Cost_for_Two,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM zomato),2) AS Percent_of_Total
FROM zomato
GROUP BY CountryCode, CountryName
ORDER BY No_of_Restaurants DESC;

SELECT * FROM country_map;

-- Q2. Calendar Table using Opening_Date_Fixed / Datekey

CREATE TABLE calendar_table AS
SELECT DISTINCT
    STR_TO_DATE(Opening_Date_Fixed,'%d-%m-%Y') AS Datekey,
    YEAR(STR_TO_DATE(Opening_Date_Fixed,'%d-%m-%Y')) AS Year,
    MONTH(STR_TO_DATE(Opening_Date_Fixed,'%d-%m-%Y')) AS MonthNo,
    MONTHNAME(STR_TO_DATE(Opening_Date_Fixed,'%d-%m-%Y')) AS MonthFullName,
    CONCAT('Q',QUARTER(STR_TO_DATE(Opening_Date_Fixed,'%d-%m-%Y'))) AS Quarter,
    DATE_FORMAT(STR_TO_DATE(Opening_Date_Fixed,'%d-%m-%Y'),'%Y-%b') AS YearMonth,
    DAYOFWEEK(STR_TO_DATE(Opening_Date_Fixed,'%d-%m-%Y')) AS WeekdayNo,
    DAYNAME(STR_TO_DATE(Opening_Date_Fixed,'%d-%m-%Y')) AS WeekdayName,
    CONCAT('FM',
        CASE
            WHEN MONTH(STR_TO_DATE(Opening_Date_Fixed,'%d-%m-%Y'))>=4
            THEN MONTH(STR_TO_DATE(Opening_Date_Fixed,'%d-%m-%Y'))-3
            ELSE MONTH(STR_TO_DATE(Opening_Date_Fixed,'%d-%m-%Y'))+9
        END
    ) AS FinancialMonth,
    CONCAT('FQ',
        CEIL(
            (
                CASE
                    WHEN MONTH(STR_TO_DATE(Opening_Date_Fixed,'%d-%m-%Y'))>=4
                    THEN MONTH(STR_TO_DATE(Opening_Date_Fixed,'%d-%m-%Y'))-3
                    ELSE MONTH(STR_TO_DATE(Opening_Date_Fixed,'%d-%m-%Y'))+9
                END
            )/3
        )
    ) AS FinancialQuarter
FROM zomato
WHERE Opening_Date_Fixed IS NOT NULL;
SELECT * FROM calendar_table LIMIT 20;

-- #Q3 convert the average cost for 2 column into USD dollars(currently the average cost for 2 in local currencies)
CREATE TABLE CurrencyRates (
  Currency VARCHAR(100) PRIMARY KEY,
  RateToUSD DECIMAL(10,6)
);
INSERT INTO CurrencyRates VALUES
('Indian Rupees(Rs.)',     0.012000),
('Dollar($)',              1.000000),
('NewZealand($)',          0.610000),
('Turkish Lira(TL)',       0.021000),
('Qatari Rial(QR)',        0.275000),
('Emirati Diram(AED)',     0.272000),
('Sri Lankan Rupee(LKR)',  0.003100),
('Indonesian Rupiah(IDR)', 0.000063),
('Botswana Pula(P)',       0.074000),
('Rand(R)',                0.055000),
('Brazilian Real(R$)',     0.180000);

INSERT INTO CurrencyRates (Currency, RateToUSD)
SELECT DISTINCT Currency, 1.270000 FROM zomato WHERE Currency LIKE 'Pounds%';
SELECT * FROM CurrencyRates;
ALTER TABLE zomato ADD COLUMN Average_Cost_for_two_USD DECIMAL(12,2);
SET SQL_SAFE_UPDATES = 0;
UPDATE zomato z
JOIN CurrencyRates c ON z.Currency = c.Currency
SET z.Average_Cost_for_two_USD = ROUND(z.Average_Cost_for_two * c.RateToUSD, 2);

SELECT City, Average_Cost_for_two, Currency, Average_Cost_for_two_USD 
FROM zomato LIMIT 100;

#Q4 Number of Restaurants based on City and Country 
SELECT CountryName, City, COUNT(*) AS NumRestaurants
FROM zomato
GROUP BY CountryName, City
ORDER BY NumRestaurants DESC;


#Q5 a]Number of Restuarnts opening by Year.
select c.year,count(*) As NewRestaurants 
from zomato z
join calendar_table c
on str_to_date(z.Opening_Date_Fixed, '%d-%m-%Y')=c.Datekey
group by c.Year
order by c.Year;

#Q5 b]Restaurants opening based on Year and Quarter
select c.year,c.Quarter,count(*) As NewRestaurants 
from zomato z
join calendar_table c
on str_to_date(z.Opening_Date_Fixed, '%d-%m-%Y')=c.Datekey
group by c.Year,c.Quarter
order by c.Year,c.Quarter;

#Q5 c]Restaurants opening based on Year and Month
select c.year,c.MonthFullName,count(*) As NewRestaurants 
from zomato z
join calendar_table c
on str_to_date(z.Opening_Date_Fixed, '%d-%m-%Y')=c.Datekey
group by c.Year,c.MonthFullName,c.MonthNo
order by c.Year,c.MonthNo;

#Q6 Count of Restaurants based on Average Rating
SELECT
Rating,
COUNT(*) AS Restaurants
FROM zomato
GROUP BY Rating
ORDER BY Rating DESC;

#Q7 Create Buckets  based on Average Price of Resonable  size and find out how many resturants  falls in local currencies.
SELECT
CASE
WHEN Average_Cost_for_two<500 THEN 'Low'
WHEN Average_Cost_for_two<1000 THEN 'Medium'
WHEN Average_Cost_for_two<3000 THEN 'High'
ELSE 'Luxury'
END AS PriceBucket,
COUNT(*) AS Restaurants
FROM zomato
GROUP BY PriceBucket;

#Q8 Percentage of restaurants based on "Has Table booking"
SELECT
Has_Table_booking,
COUNT(*)*100.0/
(SELECT COUNT(*) FROM zomato)
AS Percentage
FROM zomato
GROUP BY Has_Table_booking;

#Q9 Percentage of Restaurants based on "Has Online Delivery"
SELECT
Has_Online_delivery,
COUNT(*)*100.0/
(SELECT COUNT(*) FROM zomato)
AS Percentage
FROM zomato
GROUP BY Has_Online_delivery;

#Q10 Devlop charts based on Cuisnes,city ,Rating
-- Top Cuisines
select 
Cuisines,
count(*) 
from zomato
group by Cuisines
order by COUNT(*) desc;

-- Top Cities 
SELECT
City,
COUNT(*)
FROM zomato
GROUP BY City
ORDER BY COUNT(*) DESC;

-- Average Rating By Country 
SELECT
    CountryName,
    ROUND(AVG(Rating), 2) AS Average_Rating
FROM zomato
GROUP BY CountryName
ORDER BY Average_Rating DESC;

-- EXTRA KPI 1: Total Restaurants, Countries, Cities, Avg Rating, Total Votes
SELECT
    COUNT(*) AS Total_Restaurants,
    COUNT(DISTINCT CountryName) AS Total_Countries,
    COUNT(DISTINCT City) AS Total_Cities,
    ROUND(AVG(Rating),2) AS Average_Rating,
    SUM(Votes) AS Total_Votes,
    ROUND(AVG(Average_Cost_for_two),0) AS Avg_Cost_for_Two
FROM zomato;

-- EXTRA KPI 2: Top 10 restaurants by votes
SELECT RestaurantName, City, CountryName, Rating, Votes
FROM zomato
ORDER BY Votes DESC
LIMIT 10;

-- EXTRA KPI 3: Online delivery + table booking combination
SELECT Has_Online_delivery, Has_Table_booking, COUNT(*) AS No_of_Restaurants,
       ROUND(AVG(Rating),2) AS Avg_Rating
FROM zomato
GROUP BY Has_Online_delivery, Has_Table_booking
ORDER BY No_of_Restaurants DESC;

-- EXTRA KPI 4: Top 10 cities by average rating, minimum 20 restaurants
SELECT City, CountryName, COUNT(*) AS No_of_Restaurants, ROUND(AVG(Rating),2) AS Avg_Rating
FROM zomato
GROUP BY City, CountryName
HAVING COUNT(*) >= 20
ORDER BY Avg_Rating DESC
LIMIT 10;

-- EXTRA KPI 5: Price label performance
SELECT PriceLabel, COUNT(*) AS No_of_Restaurants,
       ROUND(AVG(Rating),2) AS Avg_Rating,
       ROUND(AVG(Average_Cost_for_two),0) AS Avg_Cost_for_Two
FROM zomato
GROUP BY PriceLabel
ORDER BY No_of_Restaurants DESC;
