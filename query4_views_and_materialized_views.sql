-- ============================================================
-- 04. VIEWS & MATERIALIZED VIEWS
-- Bank Loan Report | PostgreSQL
-- Concepts: reusable query objects, refresh strategy for BI tools.
-- ============================================================

-- A live view: recalculates on every query. Good for KPIs that
-- must always reflect the latest row (dashboards read this
-- directly instead of embedding Custom SQL in Tableau/Power BI).
CREATE OR REPLACE VIEW vw_loan_summary_kpis AS
WITH bounds AS (
    SELECT
        date_trunc('month', MAX(issue_date))                      AS mtd_start,
        date_trunc('month', MAX(issue_date) - INTERVAL '1 month') AS pmtd_start
    FROM bank_loan_data
)
SELECT
    COUNT(id)                                                                     AS total_applications,
    COUNT(id) FILTER (WHERE date_trunc('month', issue_date) = b.mtd_start)        AS mtd_applications,
    COUNT(id) FILTER (WHERE date_trunc('month', issue_date) = b.pmtd_start)       AS pmtd_applications,
    SUM(loan_amount)                                                              AS total_funded_amount,
    SUM(loan_amount) FILTER (WHERE date_trunc('month', issue_date) = b.mtd_start) AS mtd_funded_amount,
    SUM(total_payment)                                                            AS total_amount_received,
    ROUND(AVG(int_rate) * 100, 2)                                                 AS avg_int_rate,
    ROUND(AVG(dti) * 100, 2)                                                      AS avg_dti
FROM bank_loan_data, bounds b
GROUP BY b.mtd_start, b.pmtd_start;


CREATE OR REPLACE VIEW vw_loan_status_grid AS
SELECT
    loan_status,
    COUNT(id)                                                          AS loan_count,
    SUM(loan_amount)                                                   AS total_funded_amount,
    SUM(total_payment)                                                 AS total_amount_received,
    ROUND(AVG(int_rate) * 100, 2)                                      AS interest_rate,
    ROUND(AVG(dti) * 100, 2)                                           AS dti,
    ROUND(SUM(loan_amount) * 100.0 / SUM(SUM(loan_amount)) OVER (), 2) AS pct_of_total_funded
FROM bank_loan_data
GROUP BY loan_status;


-- A materialized view: computed once, stored on disk, and only
-- refreshed on demand. Use for heavier aggregations (like a full
-- monthly trend scan) that don't need to be live on every dashboard
-- click -- cheaper for the BI tool to query.
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_monthly_trend AS
SELECT
    date_trunc('month', issue_date)::date AS month_start,
    TRIM(TO_CHAR(issue_date, 'Month'))    AS month_name,
    COUNT(id)                             AS total_loan_applications,
    SUM(loan_amount)                      AS total_funded_amount,
    SUM(total_payment)                    AS total_amount_received
FROM bank_loan_data
GROUP BY 1, 2;

CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_monthly_trend_month ON mv_monthly_trend (month_start);

-- Run after every new data load (schedule via cron / Airflow / dbt):
-- REFRESH MATERIALIZED VIEW CONCURRENTLY mv_monthly_trend;
