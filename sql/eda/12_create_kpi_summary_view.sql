-- ============================================================
-- EDA Q12: Build a second, pre-aggregated VIEW specifically for the
--           dashboard's top-line KPI cards (the big numbers at the
--           top of a Power BI report).
-- Concept: CREATE VIEW with aggregation baked in
-- ============================================================

CREATE OR REPLACE VIEW vw_layoffs_kpi_summary AS
SELECT
    YEAR(`date`)                       AS layoff_year,
    country,
    industry,
    COUNT(*)                           AS total_events,
    SUM(total_laid_off)                AS total_laid_off,
    ROUND(AVG(percentage_laid_off) * 100, 1) AS avg_pct_workforce_cut,
    SUM(CASE WHEN percentage_laid_off = 1 THEN 1 ELSE 0 END) AS full_shutdowns
FROM layoffs_staging2
WHERE total_laid_off IS NOT NULL
GROUP BY YEAR(`date`), country, industry;

-- Confirm it works
SELECT * FROM vw_layoffs_kpi_summary
ORDER BY layoff_year DESC, total_laid_off DESC
LIMIT 10;
