SELECT * FROM world_layoffs.layoffs;

#Clean the Data
#1.Remove Duplicates
#2.Standardize the Data
#3.Addressing Blank and NULL values
#4. Removing rows or dropping columns which doesnot contribute to the data analysis

SELECT *
FROM layoffs;

#Create a duplicate table to work on, do not work with the raw data as you can make a mistake...copy raw data to another table to work on

CREATE TABLE layoffs_stagging
LIKE layoffs;

SELECT *
FROM layoffs_stagging;
# Transfer a copy from the original raw data table to the working duplicate table
INSERT INTO layoffs_stagging
SELECT *
FROM layoffs;

#step 1: remove duplicates

WITH duplicate_CTE AS 
(
SELECT *,
ROW_NUMBER() OVER( 
partition by company, location, industry, total_laid_off, percentage_laid_off,`date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_stagging
)

SELECT * 
FROM duplicate_CTE
WHERE row_num > 1;

#create a second layoff stagging table
CREATE TABLE `layoffs_stagging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT *
FROM layoffs_stagging2
WHERE row_num >1;

INSERT INTO layoffs_stagging2
SELECT *,
ROW_NUMBER() OVER( 
partition by company, location, industry, total_laid_off, percentage_laid_off,`date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_stagging;

#delete the duplicates
DELETE
FROM layoffs_stagging2
WHERE row_num >1;

#2. Standardizing the Data - Finding issues in the data and fixing it such as spaces,symbols etc
#Clean company column :remove spacings from company entries
SELECT company, TRIM(company)
FROM layoffs_stagging2;

#update the company column to the trim version
UPDATE layoffs_stagging2
SET company = TRIM(company);

SELECT *
FROM layoffs_stagging2;

#Clean location column : There was nothing to clean, column is good as is
SELECT distinct location
FROM layoffs_stagging2
ORDER BY 1;

#Clean industry column :
SELECT distinct industry
FROM layoffs_stagging2
ORDER BY 1;

#crypto, cryptocurrency same thing so update it to one name crypto

UPDATE layoffs_stagging2
SET industry = "Crypto"
WHERE industry LIKE "Crypto%";

#Clean date column : date data is text format
SELECT `date`,
str_to_date(`date`,'%m/%d/%Y')
FROM layoffs_stagging2;

#update the entries in the date column from text to date format
UPDATE layoffs_stagging2
SET `date`= str_to_date(`date`,'%m/%d/%Y');

ALTER TABLE layoffs_stagging2
MODIFY `date` DATE;

#verify the date column changed from text format to date format
DESC layoffs_stagging2;


#Clean country column : an entry had a period after the country
SELECT distinct country
FROM layoffs_stagging2
ORDER BY 1;

#removed a period from united states.
SELECT distinct country, TRIM(Trailing '.' FROM country)
FROM layoffs_stagging2
ORDER BY 1;

#update the country column with the fixed data
UPDATE layoffs_stagging2
SET country = TRIM(Trailing '.' FROM country)
WHERE country LIKE "United States%";

#3 Addressing NULL and Blank Values in the table

SELECT *
FROM layoffs_stagging2
WHERE industry IS NULL OR
industry =  '';

SELECT *
FROM layoffs_stagging2
WHERE company = 'Airbnb';

UPDATE layoffs_stagging2
SET industry = NULL
WHERE industry = '';


Select *
FROM layoffs_stagging2 t1
JOIN layoffs_stagging2 t2
	ON t1.company = t2.company
WHERE (t1.industry is NULL or t1.industry ='')
AND t2.industry is NOT NULL;

UPDATE layoffs_stagging2 t1
JOIN layoffs_stagging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry is NULL
AND t2.industry is NOT NULL;

SELECT *
FROM layoffs_stagging2
WHERE total_laid_off IS NULL AND
percentage_laid_off IS NULL;

#4 Deleting rows and columns that dont contribute to the data set
#Delete entries that serve no purpose
DELETE
FROM layoffs_stagging2
WHERE total_laid_off IS NULL AND
percentage_laid_off IS NULL;

#DROP a column that is not needed
ALTER TABLE layoffs_stagging2
DROP COLUMN row_num;

SELECT *
FROM layoffs_stagging2;