-- ============================================================
-- EDA Q1: What is the overall scale and timeframe of this dataset?
-- Concept: Basic aggregation (COUNT, SUM, MIN, MAX)
-- ============================================================

SELECT
    COUNT(*)                          AS total_layoff_events,
    COUNT(DISTINCT company)           AS unique_companies,
    COUNT(DISTINCT country)           AS countries_affected,
    SUM(total_laid_off)               AS total_employees_laid_off,
    MIN(`date`)                       AS earliest_event,
    MAX(`date`)                       AS latest_event,
    ROUND(SUM(total_laid_off) /
          COUNT(DISTINCT company), 0) AS avg_layoffs_per_company
FROM layoffs_staging2;

--  Between 2020-03-11 and 2026-06-12, 921130 employees were laid off 
-- across 2541 companies in 60 countries.








