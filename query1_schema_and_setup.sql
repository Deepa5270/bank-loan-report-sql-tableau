-- ============================================================
-- 01. SCHEMA & SETUP
-- Bank Loan Report | PostgreSQL
-- ============================================================
-- Run this first. Creates the table, loads expectations for the
-- source CSV, and builds the indexes the rest of the project
-- relies on.
-- ============================================================

DROP TABLE IF EXISTS bank_loan_data;

CREATE TABLE bank_loan_data (
    id                     BIGINT PRIMARY KEY,
    address_state          VARCHAR(2),
    application_type       VARCHAR(20),
    emp_length             VARCHAR(20),
    emp_title              VARCHAR(200),
    grade                  VARCHAR(2),
    home_ownership         VARCHAR(20),
    issue_date             DATE,
    last_credit_pull_date  DATE,
    last_payment_date      DATE,
    loan_status            VARCHAR(20),
    next_payment_date      DATE,
    member_id              BIGINT,
    purpose                VARCHAR(30),
    sub_grade              VARCHAR(3),
    term                   VARCHAR(15),
    verification_status    VARCHAR(30),
    annual_income          NUMERIC,
    dti                    NUMERIC,
    installment            NUMERIC,
    int_rate                NUMERIC,
    loan_amount            NUMERIC,
    total_acc              INT,
    total_payment          NUMERIC
);

-- Load data (adjust path to wherever the CSV lives locally):
-- \copy bank_loan_data FROM 'data/bank_loan_data.csv' WITH (FORMAT csv, HEADER true);

-- ---------- Cleanup ----------
-- Source file has a leading space on term values (' 36 months').
UPDATE bank_loan_data SET term = TRIM(term);

-- ---------- Indexes ----------
-- Matched to the columns the dashboard filters, groups, or joins on.
CREATE INDEX IF NOT EXISTS idx_bank_loan_issue_date ON bank_loan_data (issue_date);
CREATE INDEX IF NOT EXISTS idx_bank_loan_status      ON bank_loan_data (loan_status);
CREATE INDEX IF NOT EXISTS idx_bank_loan_state       ON bank_loan_data (address_state);
CREATE INDEX IF NOT EXISTS idx_bank_loan_purpose     ON bank_loan_data (purpose);
CREATE INDEX IF NOT EXISTS idx_bank_loan_grade       ON bank_loan_data (grade);

-- ---------- Sanity checks ----------
SELECT COUNT(*) AS row_count FROM bank_loan_data;
SELECT MIN(issue_date) AS earliest, MAX(issue_date) AS latest FROM bank_loan_data;
SELECT COUNT(*) FILTER (WHERE id IS NULL)          AS null_ids,
       COUNT(*) FILTER (WHERE loan_amount IS NULL) AS null_loan_amounts
FROM bank_loan_data;
