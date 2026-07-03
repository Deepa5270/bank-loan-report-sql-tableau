# Data Dictionary — `bank_loan_data`

| Column | Type | Description |
|---|---|---|
| id | BIGINT (PK) | Unique loan application ID |
| address_state | VARCHAR(2) | US state code of the borrower |
| application_type | VARCHAR(20) | Individual or joint application |
| emp_length | VARCHAR(20) | Borrower's employment length (e.g. "5 years") |
| emp_title | VARCHAR(200) | Borrower's job title |
| grade | VARCHAR(2) | Lending grade (A–G) |
| home_ownership | VARCHAR(20) | Rent / Own / Mortgage |
| issue_date | DATE | Date the loan was issued |
| last_credit_pull_date | DATE | Most recent date the borrower's credit was pulled |
| last_payment_date | DATE | Date of the most recent payment |
| loan_status | VARCHAR(20) | Fully Paid / Current / Charged Off |
| next_payment_date | DATE | Scheduled date of the next payment |
| member_id | BIGINT | Borrower ID |
| purpose | VARCHAR(30) | Stated reason for the loan |
| sub_grade | VARCHAR(3) | Finer-grained lending grade |
| term | VARCHAR(15) | Loan term (" 36 months" / " 60 months") |
| verification_status | VARCHAR(30) | Income verification status |
| annual_income | NUMERIC | Borrower's stated annual income |
| dti | NUMERIC | Debt-to-income ratio |
| installment | NUMERIC | Monthly installment amount |
| int_rate | NUMERIC | Interest rate (decimal, e.g. 0.12 = 12%) |
| loan_amount | NUMERIC | Amount funded |
| total_acc | INT | Total number of credit accounts |
| total_payment | NUMERIC | Total amount received to date |

## Business rules

- **Good loan** = `loan_status IN ('Fully Paid', 'Current')`
- **Bad loan** = `loan_status = 'Charged Off'`
- **MTD** = rows where `issue_date` falls in the same month as `MAX(issue_date)` in the table
- **PMTD** = rows where `issue_date` falls in the month immediately before `MAX(issue_date)`'s month
- `int_rate` and `dti` are stored as decimals; multiply by 100 for display as a percentage
