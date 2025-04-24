-- Exploratory Data Analysis

SELECT * 
FROM layoffs_copy2
;

-- Comapanies with the most layoffs
SELECT company, SUM(total_laid_off), ROUND(AVG(percentage_laid_off),3)
from layoffs_copy2
group by company
order by SUM(total_laid_off) desc
limit 15
;

-- Finding out the real % of the laid out employees
-- Dividing the total amount of laid off employees by the percentage laid off in decimal format we can find the total number of oeple working at X company
-- AVG(percentage_laid_off) yields the same result surpringsingly, so I'm not sure if I'm wrong or the data is simply that similar to the average...
SELECT 
    company,
    laid_off_employees,
    ROUND(laid_off_employees / total_employees, 3) AS real_percentage_laid_off
FROM
    (SELECT 
        company,
		SUM(total_laid_off / percentage_laid_off) AS total_employees,
		SUM(total_laid_off) AS laid_off_employees
    FROM
        layoffs_copy2
    GROUP BY company
    ORDER BY total_employees DESC) AS xd
GROUP BY company
ORDER BY laid_off_employees DESC
;

-- Companies that laid off all their employees
SELECT *
from layoffs_copy2
where percentage_laid_off = 1
order by total_laid_off desc
;

-- Industries with the most layoffs
SELECT industry, SUM(total_laid_off), round((total_laid_off/percentage_laid_off),2)
from layoffs_copy2
group by industry, total_laid_off, percentage_laid_off
order by SUM(total_laid_off) desc
limit 15
;

-- Countries with the most layoffs
SELECT country, SUM(total_laid_off)
from layoffs_copy2
group by country
order by SUM(total_laid_off) desc
limit 15
;

-- Layoffs by year
SELECT YEAR(date), SUM(total_laid_off)
from layoffs_copy2
WHERE YEAR(date) IS NOT NULL
group by YEAR(date)
ORDER BY 1 DESC
;

-- A rolling total of the layoffs increasing by month/year
WITH Rolling_total AS (
SELECT SUBSTRING(date, 1, 7) AS month, SUM(total_laid_off) AS total_layoffs
FROM layoffs_copy2
WHERE SUBSTRING(date, 1, 7) IS NOT NULL
GROUP BY month
ORDER BY 1
)
SELECT month, total_layoffs, SUM(total_layoffs) OVER(ORDER BY month) AS rolling_total
from Rolling_total
;

-- Ranking of companies with the most layoffs by year
SELECT *
FROM (
select company, YEAR(date) as years, SUM(total_laid_off), DENSE_RANK() OVER (PARTITION BY YEAR(date) ORDER BY SUM(total_laid_off) DESC) as Ranking
from layoffs_copy2
WHERE total_laid_off IS NOT NULL AND YEAR(date) IS NOT NULL
GROUP BY company, years
) as Company_ranking
WHERE Ranking <= 5
ORDER BY years
;
















