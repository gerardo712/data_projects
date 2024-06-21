-- Exploratory Data Analysis

SELECT *
FROM layoffs_staging2;

SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging;

-- Finding companies that went under completely 
-- and sorting by most people laid off to least
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;

-- Grouping rows by company and seeing total layoffs
SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

-- Finding the Date Range of the Data 
-- 3 years since the start of covid
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;

-- Grouping rows by industry and seeing total layoffs
SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;

-- Grouping rows by country and seeing total layoffs
SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

-- Grouping rows by year and seeing total layoffs
SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;

-- Grouping rows by stage and seeing total layoffs
SELECT stage, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;

-- Group rows by month-year and giving the total layoffs
SELECT SUBSTRING(`date`, 1, 7) AS `MONTH`, SUM(total_laid_off) 
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1;

-- Giving a rolling total of total layoffs per month
WITH Rolling_Total AS
(
SELECT SUBSTRING(`date`, 1, 7) AS `MONTH`, SUM(total_laid_off) AS total_off
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1
)
SELECT `MONTH`, total_off, SUM(total_off) OVER(ORDER BY `MONTH` ) AS rolling_total
FROM Rolling_Total;


-- Company layoffs by year
SELECT company, YEAR(`date`) AS `year`, SUM(total_laid_off) AS total_off
FROM layoffs_staging2
GROUP BY company, `year`
ORDER BY 3 DESC;

-- Ranking company layoffs by year, and then ordering by ranking
-- Without order by, the table displays all the companys for 2020 ranked in descending order
-- then 2021 companies ranked in descending order, 2022, 2023

-- With Order By Ranking, it shows top layoff for 20,21,22,23 then 2nd for each year, then 3rd, etc
WITH Company_Year (company, years, total_laid_off) AS
(
SELECT company, YEAR(`date`) AS `year`, SUM(total_laid_off) AS total_off
FROM layoffs_staging2
GROUP BY company, `year`
)
SELECT *, DENSE_RANK() OVER(PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
FROM Company_Year
WHERE years IS NOT NULL
ORDER BY Ranking;

-- This gives us top 5 company layoffs for every year
WITH Company_Year (company, years, total_laid_off) AS
(
SELECT company, YEAR(`date`) AS `year`, SUM(total_laid_off) AS total_off
FROM layoffs_staging2
GROUP BY company, `year`
), Company_Year_Rank AS
(SELECT *, DENSE_RANK() OVER(PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
FROM Company_Year
WHERE years IS NOT NULL)
SELECT *
FROM Company_Year_Rank
WHERE Ranking <= 5;

