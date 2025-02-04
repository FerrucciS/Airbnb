USE airbnb;

-- Create new listings with only relevant columns
CREATE TABLE new_listings AS
SELECT
	id,
    listing_url,
    host_id,
	name,
	description,
	neighbourhood,
	neighbourhood_cleansed AS council,
	latitude,
	longitude,
	property_type,
	room_type,
	accommodates,
	bathrooms_text,
	bedrooms,
	beds,
	amenities,
    CHAR_LENGTH(amenities) - CHAR_LENGTH(REPLACE(amenities, ',', '')) + 1 AS num_amenitites,
	price,
	minimum_nights,
	maximum_nights,
	number_of_reviews,
	-- This is the average accross other ratings
	review_scores_rating
FROM listings;

---------------------------------------------------------------------------------------------------
-- How many columns do we have?
---------------------------------------------------------------------------------------------------


SELECT COUNT(*) FROM new_listings;
-- 10708 columns.

---------------------------------------------------------------------------------------------------
-- Ways of finding repeated values 
---------------------------------------------------------------------------------------------------


SELECT
	id,
    COUNT(id)
FROM new_listings
GROUP BY id
HAVING COUNT(id) > 1;
-- No duplicates in id.


SELECT council, COUNT(*)
FROM new_listings
GROUP BY council
HAVING COUNT(*) >1;


-- 
WITH duplicates AS 
(
SELECT *,
ROW_NUMBER() OVER(PARTITION BY id) AS row_num
FROM new_listings
)

SELECT *
FROM duplicates
WHERE row_num > 1;
   

---------------------------------------------------------------------------------------------------
-- Missing values.
---------------------------------------------------------------------------------------------------


-- Check colums for null values
SELECT SUM(ISNULL(id)),
	SUM(ISNULL(listing_url)),
	SUM(ISNULL(host_id)),
    SUM(ISNULL(name)),
	SUM(ISNULL(description)),
	SUM(ISNULL(neighbourhood)),
	SUM(ISNULL(council)),
	SUM(ISNULL(latitude)),
	SUM(ISNULL(longitude)),
	SUM(ISNULL(property_type)),
	SUM(ISNULL(room_type)),
	SUM(ISNULL(accommodates)),
	SUM(ISNULL(bathrooms_text)),
	SUM(ISNULL(bedrooms)),
	SUM(ISNULL(beds)),
	SUM(ISNULL(amenities)),
	SUM(ISNULL(price)),
	SUM(ISNULL(minimum_nights)),
	SUM(ISNULL(maximum_nights)),
	SUM(ISNULL(number_of_reviews)),
	SUM(ISNULL(review_scores_rating))
FROM new_listings
-- 0 null values.


-- Check for empty strings or negative int, doubles. Not going to bother with latitude/longitude.
SELECT SUM(CASE WHEN id < 0 THEN 1 ELSE 0 END),
	SUM(TRIM(listing_url) LIKE ''),
    SUM(CASE WHEN host_id < 0 THEN 1 ELSE 0 END),
	SUM(TRIM(name) LIKE ''),
	SUM(TRIM(description) LIKE ''),
	SUM(TRIM(neighbourhood) LIKE ''),
	SUM(TRIM(council) LIKE ''),
	SUM(TRIM(property_type) LIKE ''),
	SUM(TRIM(room_type) LIKE ''),
	SUM(CASE WHEN accommodates < 0 THEN 1 ELSE 0 END),
	SUM(TRIM(bathrooms_text) LIKE ''),
	SUM(TRIM(bedrooms) LIKE ''),
	SUM(CASE WHEN beds < 0 THEN 1 ELSE 0 END),
	SUM(TRIM(amenities) LIKE '[]'),
	SUM(TRIM(price) LIKE ''),
	SUM(CASE WHEN minimum_nights < 0 THEN 1 ELSE 0 END),
	SUM(CASE WHEN maximum_nights < 0 THEN 1 ELSE 0 END),
	SUM(CASE WHEN number_of_reviews < 0 THEN 1 ELSE 0 END),
	SUM(CASE WHEN review_scores_rating < 0 THEN 1 ELSE 0 END)
FROM new_listings
-- description 124 empty
-- neighbourhood 3010 empty
-- bathrooms_text 8 empty
-- bedrooms 2972 empty
-- amenities 7 empty


---------------------------------------------------------------------------------------------------
-- Fix missing values.
---------------------------------------------------------------------------------------------------
-- Only missing values which can be amended are neighbourhood, bathroom_text, bedrooms.

-------------------------------
-- Neighbourhoods


-- In the "name" column we have info about suburbs. Let's unpack this info.
SELECT name, SUBSTRING(name, LOCATE(' in', name) + LENGTH(' in') + 1, LOCATE('·', name) - LOCATE(' in', name) - 4),
FROM new_listings
WHERE neighbourhood = ''
-- This returns the suburbs from the 'name' column.
-- I noticed after "in" there was the suburb. Then immediately after the suburb there was "·". This allowed me to use SUBSTRING to extract the string starting after "in" but before ·.


-- Update
UPDATE new_listings
SET
	neighbourhood = SUBSTRING(name, LOCATE(' in', name) + LENGTH(' in') + 1, LOCATE('·', name) - LOCATE(' in', name) - 4)
WHERE neighbourhood = ''


-- Now seperate column into suburb, state, country. Only keep suburb though
-- Some are separated by Suburb, City,... others by Suburb. city, ...
UPDATE new_listings
SET
	neighbourhood = SUBSTRING(neighbourhood, 1, 
		LEAST(
			IF(LOCATE(',', neighbourhood) > 1, LOCATE(',', neighbourhood) - 1, LENGTH(neighbourhood) + 1),
            IF(LOCATE('.', neighbourhood) > 1, LOCATE('.', neighbourhood) - 1, LENGTH(neighbourhood) + 1)
		) 
	)


-- Check new. 
SELECT neighbourhood FROM new_listings


-- By inspection there are still some left as "suburb/Melbourne" or "suburb (Melbourne)". Lets change these
UPDATE new_listings
SET
	neighbourhood = SUBSTRING(neighbourhood, 1, 
		LEAST(
			IF(LOCATE('(', neighbourhood) > 1, LOCATE('(', neighbourhood) - 1, LENGTH(neighbourhood) + 1),
            IF(LOCATE('/', neighbourhood) > 1, LOCATE('/', neighbourhood) - 1, LENGTH(neighbourhood) + 1)
		) 
	);



-- We have "st kilda" and Saint Kilda" these are the same
UPDATE new_listings
SET neighbourhood = CONCAT('St ', (SUBSTRING(neighbourhood, LOCATE('Saint ', neighbourhood))) )
Where TRIM(neighbourhood) LIKE 'Saint %';


-- Trim whitespace
UPDATE new_listings
SET neighbourhood = TRIM(neighbourhood)



-- Check new. 
SELECT neighbourhood FROM new_listings WHERE neighbourhood LIKE ''


-------------------------------
-- bedrooms .


-- Check info on bedrooms from name.
SELECT name, bedrooms FROM new_listings WHERE TRIM(bedrooms) LIKE ''


-- Update
UPDATE new_listings
SET
	bedrooms = CASE
			WHEN name LIKE '%Studio%' THEN '0 bedroom'
			WHEN name LIKE '%bedroom %' THEN SUBSTRING(name, LOCATE('bedroom ', name) - 2, LENGTH('x bedroom') )
			WHEN name LIKE '%bedrooms%' THEN SUBSTRING(name, LOCATE('bedrooms', name) - 2, LENGTH('x bedrooms') )
	END
WHERE TRIM(bedrooms) = '';


-- Check. We only have empty or null values for those we can't extract information from 'name'.
SELECT name, description, bedrooms FROM new_listings WHERE TRIM(bedrooms) LIKE '' OR bedrooms IS NULL;


-- From the 16 NULL bedroom values in the description 4 are studios so I can update them
UPDATE new_listings
SET 
	bedrooms = '0'
WHERE bedrooms IS NULL AND description LIKE '%studio%'


-- Lets check the listing_url to see if we can find the missing 12 bedroom values
SELECT id, listing_url, bedrooms FROM new_listings WHERE TRIM(bedrooms) LIKE '' OR bedrooms IS NULL;

-- Found the missing values from the sight and some were outdated. I will manually update these.
-------------------------------
UPDATE new_listings
SET bedrooms = CASE
	WHEN id = 12293289 THEN '1 bedroom'
    WHEN id = 23069274 THEN '0 bedroom'
    WHEN id = 24945953 THEN '1 bedroom'
    WHEN id = 26888053 THEN '0 bedroom'
    WHEN id = 34977090 THEN '0 bedroom'
    WHEN id = 36046114 THEN '1 bedroom'
    WHEN id = 38117602 THEN '1 bedroom'
    WHEN id = 53895756 THEN '1 bedroom'
    ELSE bedrooms
END
WHERE bedrooms IS NULL;

DELETE FROM new_listings 
WHERE id IN (22488519, 40377799, 40510306, 46096289);
-------------------------------


-- Remove the word bedroom(s)
UPDATE new_listings
SET 
	bedrooms = TRIM(SUBSTRING(bedrooms, 1, 2 ))
WHERE bedrooms LIKE '%bedroom%'


-- Quickly check results thus far
SELECT bedrooms, neighbourhood FROM new_listings
-- Looks good


-------------------------------
-- bathrooms_text


-- There are 8 missing values. Lets see if name or description holds any information
SELECT name, description, bathrooms_text FROM new_listings WHERE bathrooms_text LIKE '' AND (name REGEXP '%bath%' OR description REGEXP '%bath%')
-- No information


-- Check url's
SELECT id, listing_url, bathrooms_text FROM new_listings WHERE bathrooms_text LIKE ''

-- Found the missing values from the sight and one was outdated. I will manually update these.
-------------------------------
UPDATE new_listings
SET bathrooms_text = CASE
	WHEN id = 26888053 THEN '1 bath'
    WHEN id = 26904346 THEN '1.5 shared bath'
	WHEN id = 31025816 THEN '1 bath'
    WHEN id = 35914383 THEN '2 bath'
    WHEN id = 38076289 THEN '2 bath'
	WHEN id = 38883439 THEN '1 bath'
    WHEN id = 43540050 THEN '1 shared bath'
	ELSE bathrooms_text
END
WHERE TRIM(bathrooms_text) LIKE ''; 
-- id '38883439' had no information or photos but from the information 2 bedroom townhouse i guessed 1 bathroom.


DELETE FROM new_listings 
WHERE id = 34046314;
-------------------------------
---------------------------------------------------------------------------------------------------
-- Convert data types.
---------------------------------------------------------------------------------------------------
-- 'bedrooms' from TEXT to INT

-- 1) Create backup table
CREATE TABLE new_listings_backup AS
SELECT * 
FROM new_listings;


-- 2) Alter column data type
ALTER TABLE new_listings
MODIFY COLUMN bedrooms INT;


-------------------------------
-- Price from TEXT to 


-- 1) Already created backup
-- 2) Alter column data type but first need to remove '$'
UPDATE new_listings
SET price = SUBSTRING(TRIM(price), LOCATE('$', price) + 1)


ALTER TABLE new_listings
MODIFY COLUMN price DECIMAL(10,2)


---------------------------------------------------------------------------------------------------
-- Double check empties
---------------------------------------------------------------------------------------------------


-- Check for empty strings again
SELECT SUM(CASE WHEN id < 0 THEN 1 ELSE 0 END),
    SUM(CASE WHEN host_id < 0 THEN 1 ELSE 0 END),
	SUM(TRIM(name) LIKE ''),
	SUM(TRIM(description) LIKE ''),
	SUM(TRIM(neighbourhood) LIKE ''),
	SUM(TRIM(council) LIKE ''),
	SUM(TRIM(property_type) LIKE ''),
	SUM(TRIM(room_type) LIKE ''),
	SUM(CASE WHEN accommodates < 0 THEN 1 ELSE 0 END),
	SUM(TRIM(bathrooms_text) LIKE ''),
	SUM(TRIM(bedrooms) LIKE ''),
	SUM(CASE WHEN beds < 0 THEN 1 ELSE 0 END),
	SUM(TRIM(amenities) LIKE '[]'),
	SUM(CASE WHEN price < 0 THEN 1 ELSE 0 END),
	SUM(CASE WHEN minimum_nights < 0 THEN 1 ELSE 0 END),
	SUM(CASE WHEN maximum_nights < 0 THEN 1 ELSE 0 END),
	SUM(CASE WHEN number_of_reviews < 0 THEN 1 ELSE 0 END),
	SUM(CASE WHEN review_scores_rating < 0 THEN 1 ELSE 0 END)
FROM new_listings;
-- description 124 empty
-- amenities 7 empty
-- Can't fix these.


---------------------------------------------------------------------------------------------------
-- Check data quality
---------------------------------------------------------------------------------------------------

-- See which prices fall ourside 3 std deviation
-------------------------------
-- Prices
-- ** NOTE ** prices normally follow lognormal distributions with long right-tails so stddev doesn't apply here but we can still visually check the results.

SELECT *
FROM new_listings
WHERE price < (SELECT AVG(price) - (3 * STDDEV(price)) FROM new_listings)
	OR price > (SELECT AVG(price) + (4 * STDDEV(price)) FROM new_listings)

-- There are a couple of suspicious listings 41472650 and 37786374. 1 bedroom apartments in Melbourne City.
-- Everything else seems fine. I will leave the two listings above but they raise concern to be flagged.


-------------------------------
-- Minimum nights

SELECT *
FROM new_listings
WHERE minimum_nights < (SELECT AVG(minimum_nights) - (3 * STDDEV(minimum_nights)) FROM new_listings)
	OR minimum_nights > (SELECT AVG(minimum_nights) + (3 * STDDEV(minimum_nights)) FROM new_listings)

-- There are 14 lisitngs above 365 days; the highest being 1125 days. These are unreasonable and I will put a max cap at 365. 
-- Even 365 seemsunlikely but this will serve as a cap.


UPDATE new_listings
SET minimum_nights = 365
WHERE minimum_nights > 365


-------------------------------
-- bedrooms

SELECT *
FROM new_listings
WHERE bedrooms < (SELECT AVG(bedrooms) - (3 * STDDEV(bedrooms)) FROM new_listings)
	OR bedrooms > (SELECT AVG(bedrooms) + (3 * STDDEV(bedrooms)) FROM new_listings)

-- 43760603 and 51095353 has 4 bedroom not 14
-- 21750782 has 3 not 11
-- 35821644 has 2 not 11

-- Update

UPDATE new_listings
SET bedrooms = CASE
	WHEN id = 43760603 THEN 4
	WHEN id = 51095353 THEN 4
    WHEN id = 21750782 THEN 3
    WHEN id = 35821644 THEN 2
	ELSE bedrooms
END;


---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
-- Now I have finished with cleaning data.
-- Store data in new database
CREATE TABLE cleaned_listings AS
SELECT * 
FROM new_listings;

ALTER TABLE cleaned_listings
	DROP COLUMN listing_url,
    DROP COLUMN name,
    DROP COLUMN description;

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
-- Now we can get an idea of the data. Averages, counts and outliers, etc.
---------------------------------------------------------------------------------------------------



SELECT name, price, room_type, bedrooms from new_listings where price < 40 AND room_type  LIKE '%Entire home%' AND bedrooms > 1
-- probably need to disregard some of these


