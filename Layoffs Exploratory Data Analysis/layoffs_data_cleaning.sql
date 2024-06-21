-- Data Cleaning


SELECT *
FROM layoffs;

-- 1. Remove Duplicates
-- 2. Standardize the Data
-- 3. Null values or blank values
-- 4. Remove Any Columns 


-- Create a Duplicate of the original table
CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT *
FROM layoffs_staging;

INSERT layoffs_staging
SELECT * 
FROM layoffs;

-- 1. Remove Duplicates:
-- Assign a row number to each row, partitioning by all columns, so that any 
-- duplicates that show up have a value other than 1.

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- To select from the row number assignment, we must make it a CTE
-- and select from the CTE.

-- This works because ROW_NUMBER numbers all the rows in one group, and if we
-- partition by each group, then ideally, every row would be unique and they would all be 1s.

-- Test to see if Company has duplicate rows
SELECT *
FROM layoffs_staging
WHERE company = "Casper";


-- Create a new table that includes the row numbers
-- Copy the create statement from the layoffs_staging table
-- to create empty table with the same column names and data types.
-- Rename and also add a new column for the row numbers.

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` bigint DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT * 
FROM layoffs_staging2;

-- Insert Data from the table into the new copy with row numbers
-- Copy the body of the earlier CTE

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;


-- Query to find the rows where row_num = 2 and delete them
-- You can query after and it should be blank

DELETE
FROM layoffs_staging2
WHERE row_num > 1;

SELECT *
FROM layoffs_staging2
WHERE row_num > 1;



-- 2. Standardizing data

-- Trim the spaces in the front and back of company names
SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

-- Look at unique industry names to find inconsistent names
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

-- Crypto had inconsistencies, so find rows with industry simliar to Crypto
SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

-- Update them to just Crypto
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Method to remove period from the end of country name
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

-- Update the table to remove the period from "United States." rows
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Fixing Date Column
SELECT `date`
FROM layoffs_staging2;

-- String to Date -> pass in column and the format being read
-- Update date column to be an actual date instead of string
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- Reformatting Date Column to be Date type instead of String
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;



-- 3. Null or Blank Values

-- Finding nulls
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Finding nulls and blanks
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';


-- If you have multiple rows of the same company, you can fill in some nulls based on other rows 
SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Bally%';


SELECT *
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

-- Ran into an issue with the original query
-- Solution, turn all blanks to nulls first

UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- Join Table with itself,
-- Find another row of the same company with a non null industry field in table 2
-- set table 1's null industry = table 2's non null industry
-- now all the industry fields (that had a non null match somewhere)should be non null
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;


SELECT *
FROM layoffs_staging2 t1
WHERE t1.company = 'Airbnb';

-- We can't fill in the data for total and percent with what we have in the table
-- we just have to get rid of it because we can't trust it/it doesn't help us
DELETE 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT *
FROM layoffs_staging2;


-- 4. Remove Columns

-- Drop row_num column because we won't need it anymore
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;


