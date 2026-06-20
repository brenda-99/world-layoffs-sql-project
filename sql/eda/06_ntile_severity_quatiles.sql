-- ============================================================
-- EDA Q6: If we split every company into four equal-sized groups
--          by layoff size, what does the top 25% look like, and
--          how different are they from the bottom 25%?
-- Concept: NTILE(4) -- quartile segmentation
-- ============================================================


WITH company_totals AS (
    SELECT
        company,
        SUM(total_laid_off) AS total_layoffs
    FROM layoffs_staging2
    WHERE total_laid_off IS NOT NULL
    GROUP BY company
),
quartiled AS (
    SELECT
        company,
        total_layoffs,
        NTILE(4) OVER (ORDER BY total_layoffs DESC) AS severity_quartile
    FROM company_totals
)
SELECT
    severity_quartile,
    COUNT(*)                  AS companies_in_group,
    MIN(total_layoffs)        AS smallest_in_group,
    MAX(total_layoffs)        AS largest_in_group,
    ROUND(AVG(total_layoffs)) AS avg_in_group,
    SUM(total_layoffs) 		  AS total_in_group
FROM quartiled
GROUP BY severity_quartile
ORDER BY severity_quartile;

-- Quartile 1 -- the top 25% of companies by layoff size -- averaged
--  1612 layoffs per company, compared to just 23 in the bottom quartile
--  A small number of companies are driving the
--  vast majority of total job losses
