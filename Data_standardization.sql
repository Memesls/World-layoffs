-- Create a duplicate of the original table in case we need the raw data as a backup
CREATE TABLE layoffs_copy AS 
(SELECT * 
FROM layoffs)
;

SELECT *
FROM layoffs_copy
;

DESCRIBE layoffs_copy
;

UPDATE layoffs_copy
SET date = STR_TO_DATE(date, '%m/%d/%Y')
;

ALTER TABLE layoffs_copy
MODIFY COLUMN date date
;

-- 1. Remove duplicate rows
-- Create cte and filter duplicated rows
with duplicate_cte as (
select *,
row_number() over(partition by 
company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions) as row_num
from layoffs_copy
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1
;

-- Copy the table and add the row_number() column
CREATE TABLE `layoffs_copy2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` date DEFAULT NULL,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Insert the original data + the row_number into the new table
INSERT INTO layoffs_copy2
SELECT *,
row_number() over(partition by 
company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions) as row_num
from layoffs_copy
;

select *
from layoffs_copy2
WHERE row_num > 1
;

-- Delete the duplicates
DELETE 
FROM layoffs_copy2
WHERE row_num > 1
;

-- 2. Sandardize the data

-- Standardizing company
SELECT company, TRIM(company)
FROM layoffs_copy2
;

UPDATE layoffs_copy2 
SET company = TRIM(company)
;

-- Standardizing industry
SELECT DISTINCT industry
FROM layoffs_copy2
ORDER BY 1
;

SELECT *
FROM layoffs_copy2
WHERE industry LIKE "Crypto%"
;

UPDATE layoffs_copy2 
SET industry = "Crypto"
WHERE industry LIKE "Crypto%"
;

-- Standardizing location
SELECT DISTINCT location
FROM layoffs_copy2
ORDER BY 1
;

UPDATE layoffs_copy2 
SET location = "Dusseldorf"
WHERE location LIKE "DÃ¼sseldorf"
;

UPDATE layoffs_copy2 
SET location = "Florianopolis"
WHERE location LIKE "FlorianÃ³polis"
;

UPDATE layoffs_copy2 
SET location = "Malmo"
WHERE location LIKE "MalmÃ¶"
;

-- Standardizing country
SELECT DISTINCT country
FROM layoffs_copy2
ORDER BY 1
;

UPDATE layoffs_copy2 
SET country = "United States"
WHERE country LIKE "United States."
;


-- 3. Remove null or blank values

SELECT *
FROM layoffs_copy2
WHERE industry IS NULL
;

-- Converting blank values into null
UPDATE layoffs_copy2 
SET industry = NULL
WHERE industry = ""
;

-- Self joining the table to check which companies are missing an industry
SELECT t1.company, t1.industry, t2.company, t2.industry
FROM layoffs_copy2 t1 
JOIN layoffs_copy2 t2
ON t1.company = t2.company
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL
;

-- Updating the industry with a self join
UPDATE layoffs_copy2 t1
JOIN layoffs_copy2 t2
ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL
;

-- Deleting rows without layoff values since this is a layoffs table
SELECT *
FROM layoffs_copy2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL
;

DELETE 
FROM layoffs_copy2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL
;

-- 4. Remove any columns

SELECT *
FROM layoffs_copy2
;

-- Removing the row_num column we added
ALTER TABLE layoffs_copy2
DROP COLUMN row_num
;
