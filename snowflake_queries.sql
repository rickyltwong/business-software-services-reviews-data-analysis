-- Create a temporary stage in Snowflake, a logical reference to S3
CREATE
    OR REPLACE TEMPORARY STAGE g2_stage
    FILE_FORMAT = (TYPE = JSON)
    CREDENTIALS = (AWS_KEY_ID = 'AWS_KEY', AWS_SECRET_KEY = 'AWS_SECRET')
    URL = 's3://g2.webscrape.de/g2.json';

-- Exploratory Queries
SELECT *
FROM @g2_stage;
SELECT g2_flat.*
FROM (SELECT $1 json_data FROM @g2_stage src) g2
   , lateral flatten(input => g2.json_data) g2_flat

SELECT lower(g2_flat.value['input']['company_name']) AS company_name
FROM (SELECT $1 json_data
      FROM @g2_stage src) g2,
     lateral flatten(input => g2.json_data) g2_flat;

-- Create `vendor_rating` table that includes each vendor's name, their number of reviews, star rating, and categories
CREATE
    OR replace TABLE public.vendor_rating
AS
SELECT lower(g2_flat.value['input']['company_name'])    AS company_name
     , cast(value['number_of_reviews'] AS INT)          AS number_of_reviews
     , cast(value['number_of_stars'] AS NUMERIC(38, 2)) AS star_rating
     , value['categories_on_g2']                        AS category_list
FROM (SELECT $1 json_data
      FROM @g2_stage src) g2
   , lateral flatten(input => g2.json_data) g2_flat
UNION ALL
SELECT lower(g2_flat_competitors.value['competitor_name'])                  AS competitor_name
     , cast(g2_flat_competitors.value['number_of_reviews'] AS INT)             number_of_reviews
     , cast(g2_flat_competitors.value['number_of_stars'] AS NUMERIC(38, 2)) AS star_rating
     , g2_flat_competitors.value['product_category']                        AS category_list
FROM (SELECT $1 json_data
      FROM @g2_stage src) g2,
     lateral flatten(input => g2.json_data) g2_flat,
     lateral flatten(input => g2_flat.value['top_10_competitors']) g2_flat_competitors;

SELECT *
FROM vendor_rating;

-- Create the vendor_competitor_rating table that includes each vendor, their competitors, and the competitors' ratings
CREATE
    OR replace TABLE public.vendor_competitor_rating AS
SELECT lower(g2_flat.value['input']['company_name'])                        AS company_name
     , lower(g2_flat_competitors.value['competitor_name'])                  AS competitor_name
     , cast(g2_flat_competitors.value['number_of_reviews'] AS INT)             number_of_reviews
     , cast(g2_flat_competitors.value['number_of_stars'] AS NUMERIC(38, 2)) AS star_rating
FROM (SELECT $1 json_data
      FROM @g2_stage src) g2,
     lateral flatten(input => g2.json_data) g2_flat,
     lateral flatten(input => g2_flat.value['top_10_competitors']) g2_flat_competitors;

SELECT *
FROM vendor_competitor_rating;


-- Create the vendor_category table that holds the categories each vendor belongs to
CREATE
    OR replace TABLE public.vendor_category AS
SELECT lower(g2_flat_competitor.value['competitor_name']) AS company_name
     , competitor_category.value                          AS company_category
FROM (SELECT $1 json_data
      FROM @g2_stage src) g2
   , lateral flatten(input => g2.json_data) g2_flat
   , lateral flatten(input => g2_flat.value['top_10_competitors']) g2_flat_competitor
   , lateral flatten(input => g2_flat_competitor.value['product_category']) competitor_category
UNION ALL
SELECT lower(g2_flat.value['input']['company_name'])
     , category_flat.value
FROM (SELECT $1 json_data
      FROM @g2_stage src) g2
   , lateral flatten(input => g2.json_data) g2_flat
   , lateral flatten(input => g2_flat.value['categories_on_g2']) category_flat;

SELECT *
FROM vendor_category;

-- Create the vendor_category_rating table that holds the average rating of vendors in each category
CREATE
    OR replace TABLE public.vendor_category_rating AS
SELECT sum(v.number_of_reviews * v.star_rating) * 1.0 / sum(number_of_reviews) avg_stars_category
     , company_category
FROM public.vendor_rating v
         JOIN public.vendor_category c
              ON v.company_name = c.company_name
GROUP BY company_category;

SELECT *
FROM vendor_category_rating;


-- Create the vendor_category_comparison table that compares a vendor's rating with the average rating of their category
CREATE
    OR replace TABLE vendor_category_comparison
AS
SELECT avg_stars_category         AS avg_stars_category,
       lower(vc.company_name)     AS company_name,
       category_list              AS category_list,
       lower(cr.company_category) AS company_category,
       star_rating                AS star_rating
FROM vendor_category_rating cr
         JOIN vendor_category vc ON vc.company_category = cr.company_category
         JOIN vendor_rating vr ON replace(vc.company_name, '"', '') = replace(vr.company_name, '"', '');
