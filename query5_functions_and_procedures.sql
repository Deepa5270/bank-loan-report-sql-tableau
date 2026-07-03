-- ============================================================
-- 05. FUNCTIONS & PROCEDURES
-- Bank Loan Report | PostgreSQL
-- Concepts: PL/pgSQL, parameterized logic, reusable business rules.
-- ============================================================

-- Good/bad loan health for ANY date range, not just "latest month."
-- Any caller (Tableau Custom SQL, another script, an ad hoc analyst
-- query) can now reuse the same business logic instead of
-- re-deriving the good/bad loan rule every time.
CREATE OR REPLACE FUNCTION fn_loan_health(start_date DATE, end_date DATE)
RETURNS TABLE (
    good_loan_pct    NUMERIC,
    good_loan_apps   BIGINT,
    good_loan_funded NUMERIC,
    bad_loan_pct     NUMERIC,
    bad_loan_apps    BIGINT,
    bad_loan_funded  NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ROUND(COUNT(id) FILTER (WHERE loan_status IN ('Fully Paid','Current')) * 100.0 / COUNT(id), 2),
        COUNT(id) FILTER (WHERE loan_status IN ('Fully Paid','Current')),
        SUM(loan_amount) FILTER (WHERE loan_status IN ('Fully Paid','Current')),
        ROUND(COUNT(id) FILTER (WHERE loan_status = 'Charged Off') * 100.0 / COUNT(id), 2),
        COUNT(id) FILTER (WHERE loan_status = 'Charged Off'),
        SUM(loan_amount) FILTER (WHERE loan_status = 'Charged Off')
    FROM bank_loan_data
    WHERE issue_date BETWEEN start_date AND end_date;
END;
$$ LANGUAGE plpgsql;

-- Usage:
-- SELECT * FROM fn_loan_health('2021-01-01', '2021-12-31');


-- Top N loan purposes for a given state, N configurable.
-- Demonstrates a function that returns a ranked table with a
-- parameter controlling the window function's cutoff.
CREATE OR REPLACE FUNCTION fn_top_purposes_by_state(p_state VARCHAR, p_limit INT DEFAULT 3)
RETURNS TABLE (
    purpose        VARCHAR,
    applications   BIGINT,
    funded_amount  NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        b.purpose,
        COUNT(b.id)         AS applications,
        SUM(b.loan_amount)  AS funded_amount
    FROM bank_loan_data b
    WHERE b.address_state = p_state
    GROUP BY b.purpose
    ORDER BY funded_amount DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Usage:
-- SELECT * FROM fn_top_purposes_by_state('CA', 5);
