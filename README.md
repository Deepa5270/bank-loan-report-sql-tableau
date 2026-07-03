# 🏦 Bank Loan Report — SQL Analytics Project

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Database-4169E1) ![Tableau](https://img.shields.io/badge/Tableau-Dashboard-E97627) ![Live](https://img.shields.io/badge/Dashboard-Live-brightgreen) ![License](https://img.shields.io/badge/License-MIT-yellow)

![Summary Dashboard](docs/screenshots/summary.png)

🔗 **[Try the Live Dashboard Here](https://public.tableau.com/app/profile/vibes.p/viz/Bank_loan_project_17830053557660/SUMMARY)**

An end-to-end SQL analytics project analyzing a bank's consumer loan portfolio — application
volume, funded amount, collections, risk (DTI/interest rate), and loan status — culminating in a
fully interactive Tableau dashboard. Built to demonstrate SQL from schema design through advanced
window-function analytics.

---

## 🎯 Business Problem

A bank wants a single source of truth for its loan portfolio: how many applications are coming
in, how much is being funded and collected, how that's trending month over month, and how much
of the portfolio is "good" (paying) vs "bad" (charged off) — broken down by state, term, purpose,
employment length, and home ownership.

---

## ✨ Features

- KPI cards with **MTD / MoM** comparisons — applications, funded amount, amount received, interest rate, DTI
- **Good vs Bad loan** breakdown by count, funded amount, and amount received
- Loan status summary table (Charged Off / Current / Fully Paid) with per-status KPIs
- Trend, state-map, term, employment-length, and home-ownership breakdowns
- Row-level loan details with filters for Purpose, Grade, Verification Status
- Full SQL layer: raw KPI queries → CTEs/window functions → views → parameterized functions

---

## 📊 Dashboard Gallery

| Summary | Overview | Details |
|---|---|---|
| ![Summary](docs/screenshots/summary.png) | ![Overview](docs/screenshots/overview.png) | ![Details](docs/screenshots/details.png) |

👉 **[Open the live dashboard](https://public.tableau.com/app/profile/vibes.p/viz/Bank_loan_project_17830053557660/SUMMARY)** to filter by Purpose, Grade, and Verification Status yourself.

---

## 🗂️ Dataset

~38,600 loan records with borrower demographics, loan terms, and repayment status.
See [`docs/data_dictionary.md`](docs/data_dictionary.md) for the full column reference and
business rules (good/bad loan definition, MTD/PMTD logic).

---

## 🛠️ Tech Stack

| Layer | Tool |
|---|---|
| Database | PostgreSQL |
| Query logic | SQL (CTEs, window functions, views, PL/pgSQL) |
| Visualization | Tableau Public |

---

## 📁 Project Structure

```
bank-loan-sql-project/
├── README.md
├── LICENSE
├── query1_schema_and_setup.sql              # table DDL, indexes, data load, sanity checks
├── query2_basic_queries.sql                 # direct KPI queries (1:1 with dashboard cards)
├── query3_advanced_analytics.sql            # CTEs, window functions, ranking, segmentation
├── query4_views_and_materialized_views.sql  # reusable objects for the BI layer
├── query5_functions_and_procedures.sql      # parameterized PL/pgSQL functions
└── docs/
    ├── data_dictionary.md
    └── screenshots/
        ├── summary.png
        ├── overview.png
        └── details.png
```

---

## ▶️ How to Run

```bash
psql -U <user> -d <database> -f query1_schema_and_setup.sql
psql -U <user> -d <database> -f query2_basic_queries.sql
psql -U <user> -d <database> -f query3_advanced_analytics.sql
psql -U <user> -d <database> -f query4_views_and_materialized_views.sql
psql -U <user> -d <database> -f query5_functions_and_procedures.sql
```

Then point Tableau/Power BI at `bank_loan_data` directly, or at `vw_loan_summary_kpis` /
`mv_monthly_trend` for the pre-aggregated views.

---

## 🧠 SQL Concepts Demonstrated

| Concept | Where |
|---|---|
| DDL, constraints, indexing | `query1_schema_and_setup.sql` |
| Aggregation, `GROUP BY`, `CASE WHEN` | `query2_basic_queries.sql` |
| CTEs (`WITH`) | `query3_advanced_analytics.sql` |
| Window functions — `RANK`, `DENSE_RANK`, `ROW_NUMBER`, `LAG`, `NTILE`, `SUM() OVER` | `query3_advanced_analytics.sql` |
| `FILTER (WHERE ...)` for conditional aggregation | `query3_advanced_analytics.sql` |
| Percentiles — `PERCENTILE_CONT` | `query3_advanced_analytics.sql` |
| Running totals & period-over-period growth | `query3_advanced_analytics.sql` |
| Views & materialized views | `query4_views_and_materialized_views.sql` |
| PL/pgSQL functions with parameters | `query5_functions_and_procedures.sql` |
| Query performance (`EXPLAIN ANALYZE`, indexing strategy) | `query1_schema_and_setup.sql` |

---

## 🔍 Key Findings

- Good loans made up **86.2%** of the portfolio by funded amount, with Charged Off loans at 13.8%.
- Charged-off loans skew toward higher DTI quartiles and higher interest rates — see the risk
  segmentation query in `query3_advanced_analytics.sql`.
- Funded amount and applications trend upward month over month across the dataset window.
- Debt consolidation is the leading loan purpose by a wide margin, followed by credit card
  refinancing.

---

## 🚀 Next Steps

- Add a `dbt` layer on top of the views for testing and documentation
- Automate `mv_monthly_trend` refresh via a scheduled job
- Extend `fn_loan_health` into a cohort-based default-rate model

---

## 📄 License

This project is licensed under the MIT License — see [LICENSE](LICENSE) for details.
