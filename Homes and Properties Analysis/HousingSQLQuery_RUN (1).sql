/* Below statement find the average listing price for each city by joining "listing" and "location" tables. */

SELECT
    loc.city,
    AVG(price) AS avg_price
FROM
    listing l
JOIN 
    location loc ON city = loc.city  
GROUP BY
    loc.city;



SELECT
    loc.cityid,
    loc.city,
    loc.zipcode,
    AVG(price) AS avg_price
FROM
    listing l
JOIN
    location loc ON l.cityid = loc.cityid  
GROUP BY
    loc.cityid, loc.city, loc.zipcode
ORDER BY
    loc.city ASC;




/* Below statement find average listing prices per city, considering either price per square foot or additional property details. */

SELECT
    loc.city,
    AVG(l.price / l.pricepersquarefoot) AS avg_price_per_sqft
FROM
    listing l
JOIN
    location loc ON l.cityid = loc.cityid
GROUP BY
    loc.city;

	SELECT
    loc.city,
    AVG(l.price) AS avg_price,
    AVG(l.pricepersquarefoot) AS avg_sqft,
    AVG(p.bedrooms) AS avg_bedrooms,
    AVG(p.bathrooms) AS avg_bathrooms
FROM
    listing l
JOIN
    property p ON l.propertyId = p.id
JOIN
    location loc ON l.cityid = loc.cityid
GROUP BY
    loc.city;




/* Below statement identifies listings with distinct property IDs but identical prices, extracting relevant details. */

SELECT
    l1.propertyId AS property_id_1,
    l2.propertyId AS property_id_2,
    l1.price,
    loc1.city AS city_name_1,
    loc1.city AS city_1,
    loc1.countyid AS county_1,
    loc2.city AS city_name_2,
    loc2.city AS city_2,
    loc2.countyid AS county_2
FROM
    listing l1
JOIN
    listing l2 ON l1.price = l2.price AND l1.propertyId <> l2.propertyId
JOIN
    location loc1 ON l1.cityid = loc1.cityid
JOIN
    location loc2 ON l2.countyid = loc2.countyid;




/* Below statement analyze average listing prices, one based on bank-owned status and the other differentiating 
bank-owned from non-bank-owned listings in various cities.*/

SELECT
    l.is_bankowned,
    AVG(price) AS avg_price
FROM
    listing l
GROUP BY
    l.is_bankowned;

SELECT
    loc.cityid,
    loc.city,
    loc.zipcode,
    AVG(CASE WHEN l.is_bankowned = 1 THEN l.price ELSE NULL END) AS avg_bank_owned_price,
    AVG(CASE WHEN l.is_bankowned = 0 THEN l.price ELSE NULL END) AS avg_non_bank_owned_price
FROM
    listing l
JOIN
    location loc ON l.cityid = loc.cityid
GROUP BY
    loc.cityid, loc.city, loc.zipcode
ORDER BY
    loc.city ASC;

	
	
	



/* Below statement identify the top 10 counties with the highest and lowest average listing prices, 
using joins between "listing," "location," and "county" tables. */

SELECT TOP 10
    loc.countyid,
    c.county,
    AVG(l.price) AS avg_price
FROM
    listing l
JOIN
    location loc ON l.countyid = loc.countyid
JOIN
    county c ON loc.countyid = c.countyid
GROUP BY
    loc.countyid, c.county
ORDER BY
    avg_price DESC;



SELECT TOP 10
    loc.countyid,
    c.county,
    AVG(l.price) AS avg_price
FROM
    listing l
JOIN
    location loc ON l.countyid = loc.countyid
JOIN
    county c ON loc.countyid = c.countyid
GROUP BY
    loc.countyid, c.county
ORDER BY
    avg_price ASC;








/* below statement calculates the average listing price for each combination of bedrooms and bathrooms in the "listing" and "property" tables. */

SELECT
    p.bedrooms,
    p.bathrooms,
    AVG(l.price) AS avg_price
FROM
    listing l
JOIN
    property p ON l.propertyId = p.id
GROUP BY
    p.bedrooms, p.bathrooms
ORDER BY
    p.bedrooms, p.bathrooms;


USE Housing
GO



/* Below statement will create a relationship between Listing Table and Proeprty Table */
ALTER TABLE Listing
ADD CONSTRAINT fk_listing_property
FOREIGN KEY (PropertyID)
REFERENCES Property(ID);

/* Below statement will create a relationship between Listing Table and Location Table*/
ALTER TABLE Listing
ADD CONSTRAINT fk_listing_location
FOREIGN KEY (CityID)
REFERENCES Location(CityID);


/* Below statement will create a relationship between Listing Table and County Table*/
ALTER TABLE Listing
ADD CONSTRAINT fk_listing_county
FOREIGN KEY (CountyID)
REFERENCES County(CountyID);


/* Below statement will create a relationship between Location Table and County Table*/
ALTER TABLE Location
ADD CONSTRAINT fk_county_city
FOREIGN KEY (CountyID)
REFERENCES County(CountyID);


/*The below stored procedure will fetch the maximum and minimum price per square foot for a given city*/
IF OBJECT_ID('spGetMaxMinPrice') IS NOT NULL
	DROP PROC spGetMaxMinPrice;
GO
CREATE PROC spGetMaxMinPrice
	   @CityID int
AS
DECLARE  @MaxPrice smallint;
DECLARE	 @MinPrice smallint;

SELECT @MaxPrice = MAX(pricepersquarefoot),
		@MinPrice = MIN(pricepersquarefoot)
FROM listing
WHERE cityid = @CityID;
PRINT 'City: ' + CONVERT(NVARCHAR(20),@CityID);
PRINT 'Maximum Price: $' + CONVERT(NVARCHAR(20), @MaxPrice);
PRINT 'Minimum Price: $' + CONVERT(NVARCHAR(20), @MinPrice);

GO
EXEC spGetMaxMinPrice @CityID=32767;



/* The below view gives the average price/square foot for each city*/
GO
IF OBJECT_ID('AveragePriceCity') IS NOT NULL
	DROP VIEW AveragePriceCity;
GO
CREATE VIEW AveragePriceCity AS
	SELECT cityid, AVG(pricepersquarefoot) AS AveragePrice
	FROM listing
	GROUP BY cityid;
GO
SELECT * FROM AveragePriceCity 
ORDER BY cityid ASC;

/*The below query gives the list of top10 cities with highest average price/square foot from the view*/
SELECT TOP 10 AveragePriceCity.cityid, AveragePrice, city
FROM AveragePriceCity
	JOIN location ON AveragePriceCity.cityid = location.cityid
ORDER BY AveragePrice DESC;



/* Properties sold in a given year */
IF OBJECT_ID('fnGetPropertySoldByYear') IS NOT NULL
	DROP FUNCTION fnGetPropertySoldByYear;
GO
CREATE FUNCTION fnGetPropertySoldByYear
				(@Year int)
		RETURNS int
AS
BEGIN
	DECLARE @PropertyCount int;
	SELECT @PropertyCount = COUNT(*)
	FROM Listing
	WHERE YEAR(datepostedstring) = @Year 
		  AND event = 'Sold';

	RETURN @PropertyCount;
END;
GO
PRINT 'Property Count: ' + CONVERT(NVARCHAR(20), dbo.fnGetPropertySoldByYear(2021));





/* Count of Properties on kinds of event such as sold, available */

Select event,
	   COUNT(*) AS PropertyCount
FROM listing
GROUP BY event;

/* List of housing available for sale in the given price/squarefoot range */
SELECT propertyid,AveragePriceCity.cityid,
	   location.city, listing.countyid
FROM AveragePriceCity
	JOIN listing ON AveragePriceCity.cityid = listing.cityid
	JOIN location ON listing.cityid = location.cityid
WHERE event = 'Listed for Sale' AND
	  AveragePrice BETWEEN 150 AND 200
ORDER BY city;



/* List of all the properties available for sale */
GO
IF OBJECT_ID('AvailableForSale') IS NOT NULL
	DROP VIEW AvailableForSale;
GO
CREATE VIEW AvailableForSale AS
	SELECT propertyId, county, 
		   city, price, pricepersquarefoot
	FROM listing
		JOIN location ON listing.cityid = location.cityid
		JOIN county ON location.countyid = county.countyid
		WHERE listing.event = 'Listed for sale';

GO
SELECT * from AvailableForSale;























