-- ============================================================
-- EDA Q5: What does the underlying trend look like once you smooth
--          out noisy single-month spikes?
-- Concept: Moving average via window frame (ROWS BETWEEN)
-- ============================================================

WITH monthly AS (
    SELECT
        DATE_FORMAT(`date`, '%Y-%m') AS month,
        SUM(total_laid_off)          AS monthly_total
    FROM layoffs_staging2
    WHERE total_laid_off IS NOT NULL
    GROUP BY DATE_FORMAT(`date`, '%Y-%m')
)
SELECT
    month,
    monthly_total,
    ROUND(
        AVG(monthly_total) OVER (
            ORDER BY month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 0
    ) AS rolling_3mo_avg
FROM monthly
ORDER BY month;


-- While individual months are volatile, the 3-month rolling average shows a clear, 
-- sustained climb beginning in late 2022 and continuing through early 2023, 
-- this wasn't a one-off shock, it was a multi-month trend.
