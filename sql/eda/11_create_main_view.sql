-- ============================================================
-- EDA Q11: Build a single, analysis-ready VIEW that Power BI can
--           connect to directly, instead of re-running 10 separate
--           SQL scripts every time the dashboard needs to refresh.
-- Concept: CREATE VIEW
-- ============================================================

CREATE OR REPLACE VIEW vw_layoffs_enriched AS
SELECT
    company,
    location,
    country,
    industry,
    stage,
    `date`,
    YEAR(`date`)                          AS layoff_year,
    DATE_FORMAT(`date`, '%Y-%m')          AS layoff_month,
    total_laid_off,
    percentage_laid_off,
    ROUND(percentage_laid_off * 100, 1)   AS pct_laid_off_display,
    funds_raised,
    CASE
        WHEN percentage_laid_off = 1 THEN 'Full Shutdown'
        WHEN percentage_laid_off >= 0.5 THEN 'Severe (50%+)'
        WHEN percentage_laid_off >= 0.2 THEN 'Major (20-49%)'
        WHEN percentage_laid_off IS NOT NULL THEN 'Moderate (<20%)'
        ELSE 'Not Disclosed'
    END AS severity_band
FROM layoffs_staging2;

-- Confirm it works exactly like a table
SELECT * FROM vw_layoffs_enriched LIMIT 10;

--  Built a reusable SQL VIEW (vw_layoffs_enriched) as the single
--  source of truth for the Power BI dashboard -- pre-computing
--  year/month buckets and a severity classification in SQL rather
--  than in Power Query, keeping all business logic version-controlled
--  and auditable in the SQL layer
