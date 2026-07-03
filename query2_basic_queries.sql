-- ============================================================
-- BANK LOAN REPORT | PostgreSQL Query Set
-- Table: bank_loan_data
-- Adapted from SQL Server syntax -> PostgreSQL
-- MTD/PMTD are calculated DYNAMICALLY from MAX(issue_date),
-- so these queries keep working even after you load new data.
-- ============================================================

-- Suggested table load (adjust types if your loader differs)
-- CREATE TABLE bank_loan_data (
--     id                     BIGINT PRIMARY KEY,
--     address_state          VARCHAR(2),
--     application_type       VARCHAR(20),
--     emp_length             VARCHAR(20),
--     emp_title              VARCHAR(200),
--     grade                  VARCHAR(2),
--     home_ownership         VARCHAR(20),
--     issue_date             DATE,
--     last_credit_pull_date  DATE,
--     last_payment_date      DATE,
--     loan_status            VARCHAR(20),
--     next_payment_date      DATE,
--     member_id              BIGINT,
--     purpose                VARCHAR(30),
--     sub_grade              VARCHAR(3),
--     term                   VARCHAR(15),
--     verification_status    VARCHAR(30),
--     annual_income          NUMERIC,
--     dti                    NUMERIC,
--     installment            NUMERIC,
--     int_rate               NUMERIC,
--     loan_amount            NUMERIC,
--     total_acc              INT,
--     total_payment          NUMERIC
-- );

-- Note: term values have a leading space (' 36 months', ' 60 months')
-- in the source file. Wrap with TRIM(term) wherever you group/display it,
-- or clean it once with:
-- UPDATE bank_loan_data SET term = TRIM(term);


-- ============================================================
-- A. DASHBOARD 1 : SUMMARY
-- ============================================================

-- ---------- Total Loan Applications ----------
SELECT COUNT(id) AS total_applications
FROM bank_loan_data;

-- MTD (latest month present in the data)
SELECT COUNT(id) AS mtd_applications
FROM bank_loan_data
WHERE EXTRACT(MONTH FROM issue_date) = EXTRACT(MONTH FROM (SELECT MAX(issue_date) FROM bank_loan_data))
  AND EXTRACT(YEAR  FROM issue_date) = EXTRACT(YEAR  FROM (SELECT MAX(issue_date) FROM bank_loan_data));

-- PMTD (month before the latest month)
SELECT COUNT(id) AS pmtd_applications
FROM bank_loan_data
WHERE date_trunc('month', issue_date) =
      date_trunc('month', (SELECT MAX(issue_date) FROM bank_loan_data) - INTERVAL '1 month');


-- ---------- Total Funded Amount ----------
SELECT SUM(loan_amount) AS total_funded_amount
FROM bank_loan_data;

SELECT SUM(loan_amount) AS mtd_total_funded_amount
FROM bank_loan_data
WHERE date_trunc('month', issue_date) = date_trunc('month', (SELECT MAX(issue_date) FROM bank_loan_data));

SELECT SUM(loan_amount) AS pmtd_total_funded_amount
FROM bank_loan_data
WHERE date_trunc('month', issue_date) =
      date_trunc('month', (SELECT MAX(issue_date) FROM bank_loan_data) - INTERVAL '1 month');


-- ---------- Total Amount Received ----------
SELECT SUM(total_payment) AS total_amount_collected
FROM bank_loan_data;

SELECT SUM(total_payment) AS mtd_total_amount_collected
FROM bank_loan_data
WHERE date_trunc('month', issue_date) = date_trunc('month', (SELECT MAX(issue_date) FROM bank_loan_data));

SELECT SUM(total_payment) AS pmtd_total_amount_collected
FROM bank_loan_data
WHERE date_trunc('month', issue_date) =
      date_trunc('month', (SELECT MAX(issue_date) FROM bank_loan_data) - INTERVAL '1 month');


-- ---------- Average Interest Rate ----------
SELECT ROUND(AVG(int_rate) * 100, 2) AS avg_int_rate
FROM bank_loan_data;

SELECT ROUND(AVG(int_rate) * 100, 2) AS mtd_avg_int_rate
FROM bank_loan_data
WHERE date_trunc('month', issue_date) = date_trunc('month', (SELECT MAX(issue_date) FROM bank_loan_data));

SELECT ROUND(AVG(int_rate) * 100, 2) AS pmtd_avg_int_rate
FROM bank_loan_data
WHERE date_trunc('month', issue_date) =
      date_trunc('month', (SELECT MAX(issue_date) FROM bank_loan_data) - INTERVAL '1 month');


-- ---------- Average DTI ----------
SELECT ROUND(AVG(dti) * 100, 2) AS avg_dti
FROM bank_loan_data;

SELECT ROUND(AVG(dti) * 100, 2) AS mtd_avg_dti
FROM bank_loan_data
WHERE date_trunc('month', issue_date) = date_trunc('month', (SELECT MAX(issue_date) FROM bank_loan_data));

SELECT ROUND(AVG(dti) * 100, 2) AS pmtd_avg_dti
FROM bank_loan_data
WHERE date_trunc('month', issue_date) =
      date_trunc('month', (SELECT MAX(issue_date) FROM bank_loan_data) - INTERVAL '1 month');


-- ---------- GOOD LOAN KPIs (Fully Paid + Current) ----------
SELECT
    ROUND(
        (COUNT(CASE WHEN loan_status IN ('Fully Paid','Current') THEN id END) * 100.0)
        / COUNT(id), 2
    ) AS good_loan_percentage
FROM bank_loan_data;

SELECT COUNT(id) AS good_loan_applications
FROM bank_loan_data
WHERE loan_status IN ('Fully Paid', 'Current');

SELECT SUM(loan_amount) AS good_loan_funded_amount
FROM bank_loan_data
WHERE loan_status IN ('Fully Paid', 'Current');

SELECT SUM(total_payment) AS good_loan_amount_received
FROM bank_loan_data
WHERE loan_status IN ('Fully Paid', 'Current');


-- ---------- BAD LOAN KPIs (Charged Off) ----------
SELECT
    ROUND(
        (COUNT(CASE WHEN loan_status = 'Charged Off' THEN id END) * 100.0)
        / COUNT(id), 2
    ) AS bad_loan_percentage
FROM bank_loan_data;

SELECT COUNT(id) AS bad_loan_applications
FROM bank_loan_data
WHERE loan_status = 'Charged Off';

SELECT SUM(loan_amount) AS bad_loan_funded_amount
FROM bank_loan_data
WHERE loan_status = 'Charged Off';

SELECT SUM(total_payment) AS bad_loan_amount_received
FROM bank_loan_data
WHERE loan_status = 'Charged Off';


-- ---------- LOAN STATUS GRID VIEW ----------
SELECT
    loan_status,
    COUNT(id)                      AS loan_count,
    SUM(total_payment)             AS total_amount_received,
    SUM(loan_amount)                AS total_funded_amount,
    ROUND(AVG(int_rate) * 100, 2)   AS interest_rate,
    ROUND(AVG(dti) * 100, 2)        AS dti
FROM bank_loan_data
GROUP BY loan_status;

-- Same grid, MTD only
SELECT
    loan_status,
    SUM(total_payment) AS mtd_total_amount_received,
    SUM(loan_amount)   AS mtd_total_funded_amount
FROM bank_loan_data
WHERE date_trunc('month', issue_date) = date_trunc('month', (SELECT MAX(issue_date) FROM bank_loan_data))
GROUP BY loan_status;


-- ============================================================
-- B. DASHBOARD 2 : OVERVIEW
-- ============================================================

-- ---------- Monthly trend (Line Chart) ----------
SELECT
    EXTRACT(MONTH FROM issue_date)      AS month_number,
    TRIM(TO_CHAR(issue_date, 'Month'))  AS month_name,
    COUNT(id)                           AS total_loan_applications,
    SUM(loan_amount)                    AS total_funded_amount,
    SUM(total_payment)                  AS total_amount_received
FROM bank_loan_data
GROUP BY EXTRACT(MONTH FROM issue_date), TRIM(TO_CHAR(issue_date, 'Month'))
ORDER BY month_number;

-- ---------- By State (Filled Map) ----------
SELECT
    address_state AS state,
    COUNT(id)                AS total_loan_applications,
    SUM(loan_amount)         AS total_funded_amount,
    SUM(total_payment)       AS total_amount_received
FROM bank_loan_data
GROUP BY address_state
ORDER BY address_state;

-- ---------- By Term (Donut Chart) ----------
SELECT
    TRIM(term) AS term,
    COUNT(id)                AS total_loan_applications,
    SUM(loan_amount)         AS total_funded_amount,
    SUM(total_payment)       AS total_amount_received
FROM bank_loan_data
GROUP BY TRIM(term)
ORDER BY term;

-- ---------- By Employee Length (Bar Chart) ----------
SELECT
    emp_length AS employee_length,
    COUNT(id)                AS total_loan_applications,
    SUM(loan_amount)         AS total_funded_amount,
    SUM(total_payment)       AS total_amount_received
FROM bank_loan_data
GROUP BY emp_length
ORDER BY emp_length;

-- ---------- By Purpose (Bar Chart) ----------
SELECT
    purpose,
    COUNT(id)                AS total_loan_applications,
    SUM(loan_amount)         AS total_funded_amount,
    SUM(total_payment)       AS total_amount_received
FROM bank_loan_data
GROUP BY purpose
ORDER BY purpose;

-- ---------- By Home Ownership (Tree Map) ----------
SELECT
    home_ownership,
    COUNT(id)                AS total_loan_applications,
    SUM(loan_amount)         AS total_funded_amount,
    SUM(total_payment)       AS total_amount_received
FROM bank_loan_data
GROUP BY home_ownership
ORDER BY home_ownership;


-- ============================================================
-- Example: same "Purpose" breakdown filtered to Grade A only
-- (shows how any dashboard filter maps back to a WHERE clause)
-- ============================================================
SELECT
    purpose,
    COUNT(id)                AS total_loan_applications,
    SUM(loan_amount)         AS total_funded_amount,
    SUM(total_payment)       AS total_amount_received
FROM bank_loan_data
WHERE grade = 'A'
GROUP BY purpose
ORDER BY purpose;
