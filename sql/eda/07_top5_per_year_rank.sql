-- ============================================================
-- EDA Q7: Which companies led the largest layoffs in each year,
--          and does the list of "biggest cutters" change year to
--          year or is it the same names repeating?
-- Concept: DENSE_RANK() with PARTITION BY for per-group ranking
-- ============================================================

WITH yearly_totals AS 
(
SELECT company, YEAR(`date`) AS layoff_year,
SUM(total_laid_off)  AS yearly_layoffs
FROM layoffs_staging2
WHERE total_laid_off IS NOT NULL
GROUP BY company, YEAR(`date`)
),
ranked AS 
(
SELECT *,
DENSE_RANK() OVER (PARTITION BY layoff_year ORDER BY yearly_layoffs DESC) AS year_rank
FROM yearly_totals
)
SELECT layoff_year, company, yearly_layoffs, year_rank
FROM ranked
WHERE year_rank <= 5
ORDER BY layoff_year, year_rank;

-- Amazon appears in the top 5 in 2022, 2023, 2025 & 2026 -- one
--  of the few companies to repeatedly drive major layoffs across
--  multiple years rather than a single isolated event
