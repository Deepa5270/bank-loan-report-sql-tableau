-- ============================================================
-- 03. ADVANCED ANALYTICS
-- Bank Loan Report | PostgreSQL
-- Concepts: CTEs, window functions (RANK/DENSE_RANK/ROW_NUMBER/
-- LAG/NTILE), FILTER clause, running totals, percentiles.
-- ============================================================


-- ---------- 3.1 All summary KPIs (Total / MTD / PMTD) in one pass ----------
-- Replaces 9+ separate queries from the basic version with a
-- single CTE + FILTER (WHERE ...) scan.
WITH bounds AS (
    SELECT
        MAX(issue_date)                                                 AS latest_date,
        date_trunc('month', MAX(issue_date))                            AS mtd_start,
        date_trunc('month', MAX(issue_date) - INTERVAL '1 month')       AS pmtd_start
    FROM bank_loan_data
)
SELECT
    COUNT(id)                                                                       AS total_applications,
    COUNT(id)        FILTER (WHERE date_trunc('month', issue_date) = b.mtd_start)   AS mtd_applications,
    COUNT(id)        FILTER (WHERE date_trunc('month', issue_date) = b.pmtd_start)  AS pmtd_applications,
    SUM(loan_amount)                                                                 AS total_funded_amount,
    SUM(loan_amount) FILTER (WHERE date_trunc('month', issue_date) = b.mtd_start)   AS mtd_funded_amount,
    SUM(loan_amount) FILTER (WHERE date_trunc('month', issue_date) = b.pmtd_start)  AS pmtd_funded_amount,
    SUM(total_payment)                                                               AS total_amount_received,
    SUM(total_payment) FILTER (WHERE date_trunc('month', issue_date) = b.mtd_start) AS mtd_amount_received,
    SUM(total_payment) FILTER (WHERE date_trunc('month', issue_date) = b.pmtd_start) AS pmtd_amount_received,
    ROUND(AVG(int_rate) * 100, 2)                                                    AS avg_int_rate,
    ROUND(AVG(dti) * 100, 2)                                                         AS avg_dti
FROM bank_loan_data, bounds b
GROUP BY b.latest_date, b.mtd_start, b.pmtd_start;


-- ---------- 3.2 Good vs Bad loan KPIs, side by side, one scan ----------
SELECT
    ROUND(COUNT(id) FILTER (WHERE loan_status IN ('Fully Paid','Current')) * 100.0 / COUNT(id), 2) AS good_loan_pct,
    COUNT(id)        FILTER (WHERE loan_status IN ('Fully Paid','Current'))                        AS good_loan_apps,
    SUM(loan_amount) FILTER (WHERE loan_status IN ('Fully Paid','Current'))                        AS good_loan_funded,
    SUM(total_payment) FILTER (WHERE loan_status IN ('Fully Paid','Current'))                      AS good_loan_received,
    ROUND(COUNT(id) FILTER (WHERE loan_status = 'Charged Off') * 100.0 / COUNT(id), 2)              AS bad_loan_pct,
    COUNT(id)        FILTER (WHERE loan_status = 'Charged Off')                                     AS bad_loan_apps,
    SUM(loan_amount) FILTER (WHERE loan_status = 'Charged Off')                                     AS bad_loan_funded,
    SUM(total_payment) FILTER (WHERE loan_status = 'Charged Off')                                   AS bad_loan_received
FROM bank_loan_data;


-- ---------- 3.3 Loan status grid with % share of total (window fn after GROUP BY) ----------
SELECT
    loan_status,
    COUNT(id)                                                          AS loan_count,
    SUM(loan_amount)                                                   AS total_funded_amount,
    SUM(total_payment)                                                 AS total_amount_received,
    ROUND(AVG(int_rate) * 100, 2)                                      AS interest_rate,
    ROUND(AVG(dti) * 100, 2)                                           AS dti,
    ROUND(SUM(loan_amount) * 100.0 / SUM(SUM(loan_amount)) OVER (), 2) AS pct_of_total_funded
FROM bank_loan_data
GROUP BY loan_status
ORDER BY total_funded_amount DESC;


-- ---------- 3.4 Monthly trend + running total + MoM growth % ----------
WITH monthly AS (
    SELECT
        date_trunc('month', issue_date)::date AS month_start,
        TRIM(TO_CHAR(issue_date, 'Month'))    AS month_name,
        COUNT(id)                             AS total_loan_applications,
        SUM(loan_amount)                      AS total_funded_amount,
        SUM(total_payment)                    AS total_amount_received
    FROM bank_loan_data
    GROUP BY 1, 2
)
SELECT
    month_start,
    month_name,
    total_loan_applications,
    total_funded_amount,
    total_amount_received,
    SUM(total_funded_amount) OVER (ORDER BY month_start) AS running_total_funded,
    LAG(total_funded_amount) OVER (ORDER BY month_start) AS prior_month_funded,
    ROUND(
        (total_funded_amount - LAG(total_funded_amount) OVER (ORDER BY month_start))
        * 100.0 / NULLIF(LAG(total_funded_amount) OVER (ORDER BY month_start), 0)
    , 2) AS mom_growth_pct
FROM monthly
ORDER BY month_start;


-- ---------- 3.5 States ranked by funded amount ----------
SELECT
    address_state AS state,
    COUNT(id)                AS total_loan_applications,
    SUM(loan_amount)         AS total_funded_amount,
    SUM(total_payment)       AS total_amount_received,
    RANK()       OVER (ORDER BY SUM(loan_amount) DESC) AS funding_rank,
    DENSE_RANK() OVER (ORDER BY SUM(loan_amount) DESC) AS funding_dense_rank
FROM bank_loan_data
GROUP BY address_state
ORDER BY funding_rank;


-- ---------- 3.6 Top 3 loan purposes per state (ROW_NUMBER + PARTITION BY) ----------
WITH purpose_by_state AS (
    SELECT
        address_state,
        purpose,
        COUNT(id)        AS applications,
        SUM(loan_amount) AS funded_amount,
        ROW_NUMBER() OVER (PARTITION BY address_state ORDER BY SUM(loan_amount) DESC) AS rn
    FROM bank_loan_data
    GROUP BY address_state, purpose
)
SELECT address_state, purpose, applications, funded_amount
FROM purpose_by_state
WHERE rn <= 3
ORDER BY address_state, rn;


-- ---------- 3.7 Risk segmentation: DTI quartiles vs charge-off rate ----------
WITH scored AS (
    SELECT
        id, dti, int_rate, loan_status,
        NTILE(4) OVER (ORDER BY dti) AS dti_quartile
    FROM bank_loan_data
    WHERE dti IS NOT NULL
)
SELECT
    dti_quartile,
    COUNT(id)                                                             AS applications,
    ROUND(AVG(dti) * 100, 2)                                              AS avg_dti,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY int_rate) * 100, 2) AS median_int_rate,
    ROUND(PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY int_rate) * 100, 2) AS p90_int_rate,
    ROUND(COUNT(id) FILTER (WHERE loan_status = 'Charged Off') * 100.0 / COUNT(id), 2) AS charge_off_rate_pct
FROM scored
GROUP BY dti_quartile
ORDER BY dti_quartile;


-- ---------- 3.8 Grade A/B/C funded amount by purpose, pivoted with FILTER ----------
WITH grade_purpose AS (
    SELECT
        grade, purpose,
        SUM(loan_amount) AS total_funded_amount
    FROM bank_loan_data
    WHERE grade IN ('A', 'B', 'C')
    GROUP BY grade, purpose
)
SELECT
    purpose,
    SUM(total_funded_amount) FILTER (WHERE grade = 'A') AS grade_a_funded,
    SUM(total_funded_amount) FILTER (WHERE grade = 'B') AS grade_b_funded,
    SUM(total_funded_amount) FILTER (WHERE grade = 'C') AS grade_c_funded
FROM grade_purpose
GROUP BY purpose
ORDER BY purpose;
