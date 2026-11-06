/*
BANKING & LOAN ANALYTICS — TOP 10 KPI QUERIES
Database: bank_loan_db

Designed for the six-table Banking_Data project:
  fact_loan, fact_repayment, dim_client, dim_product, dim_branch, bank_transactions

HOW TO RUN
1. Open this file in MySQL Workbench.
2. Run the SETUP CHECK section first.
3. Execute each KPI SELECT separately (click inside a query and press Ctrl+Enter).

IMPORTANT
- This file does not DROP, recreate, or delete any tables or data.
- The KPIs use the normalized source tables rather than final_fact, which avoids
  ambiguity about whether final_fact was imported with the expected column names.
- If a table is missing, import its matching CSV into bank_loan_db first.
*/

USE bank_loan_db;

-- =========================================================
-- SETUP CHECK: DATABASE, TABLES, AND ROW COUNTS
-- Expected source row counts: fact_loan 2000; fact_repayment 2000;
-- dim_client 1000; dim_product 11; dim_branch 180; bank_transactions 100000.
-- =========================================================

SELECT DATABASE() AS current_database;
SHOW TABLES;

SELECT 'fact_loan' AS table_name, COUNT(*) AS total_rows FROM fact_loan
UNION ALL
SELECT 'fact_repayment', COUNT(*) FROM fact_repayment
UNION ALL
SELECT 'dim_client', COUNT(*) FROM dim_client
UNION ALL
SELECT 'dim_product', COUNT(*) FROM dim_product
UNION ALL
SELECT 'dim_branch', COUNT(*) FROM dim_branch
UNION ALL
SELECT 'bank_transactions', COUNT(*) FROM bank_transactions;

-- =========================================================
-- KPI 1: TOTAL LOAN ACCOUNTS
-- =========================================================
SELECT
    COUNT(DISTINCT account_id) AS total_loan_accounts
FROM fact_loan;

-- =========================================================
-- KPI 2: TOTAL LOAN AMOUNT
-- =========================================================
SELECT
    SUM(loan_amount) AS total_loan_amount
FROM fact_loan;

-- =========================================================
-- KPI 3: TOTAL FUNDED AMOUNT
-- =========================================================
SELECT
    SUM(funded_amount) AS total_funded_amount
FROM fact_loan;

-- =========================================================
-- KPI 4: AVERAGE LOAN AMOUNT
-- =========================================================
SELECT
    ROUND(AVG(loan_amount), 2) AS average_loan_amount
FROM fact_loan;

-- =========================================================
-- KPI 5: LOAN STATUS DISTRIBUTION
-- Includes count and percentage for every loan status.
-- =========================================================
SELECT
    loan_status,
    COUNT(*) AS loan_accounts,
    ROUND(
        COUNT(*) * 100.0 / NULLIF((SELECT COUNT(*) FROM fact_loan), 0),
        2
    ) AS percentage_of_accounts
FROM fact_loan
GROUP BY loan_status
ORDER BY loan_accounts DESC;

-- =========================================================
-- KPI 6: DEFAULT RATE
-- Uses the loan_status value in fact_loan.
-- =========================================================
SELECT
    COUNT(*) AS total_loan_accounts,
    SUM(CASE WHEN LOWER(TRIM(loan_status)) = 'default' THEN 1 ELSE 0 END)
        AS defaulted_accounts,
    ROUND(
        SUM(CASE WHEN LOWER(TRIM(loan_status)) = 'default' THEN 1 ELSE 0 END)
        * 100.0 / NULLIF(COUNT(*), 0),
        2
    ) AS default_rate_pct
FROM fact_loan;

-- =========================================================
-- KPI 7: DELINQUENCY RATE
-- Uses the repayment table's Y/N delinquency flag.
-- =========================================================
SELECT
    COUNT(*) AS repayment_accounts,
    SUM(CASE WHEN UPPER(TRIM(is_delinquent_loan)) = 'Y' THEN 1 ELSE 0 END)
        AS delinquent_accounts,
    ROUND(
        SUM(CASE WHEN UPPER(TRIM(is_delinquent_loan)) = 'Y' THEN 1 ELSE 0 END)
        * 100.0 / NULLIF(COUNT(*), 0),
        2
    ) AS delinquency_rate_pct
FROM fact_repayment;

-- =========================================================
-- KPI 8: REPAYMENT COLLECTION SUMMARY
-- Collection-to-loan ratio is descriptive, not a formal recovery rate;
-- it can exceed 100% because total payments may include interest and fees.
-- =========================================================
SELECT
    SUM(l.loan_amount) AS total_loan_amount,
    SUM(COALESCE(r.total_pymnt, 0)) AS total_repayments_received,
    ROUND(
        SUM(COALESCE(r.total_pymnt, 0)) * 100.0
        / NULLIF(SUM(l.loan_amount), 0),
        2
    ) AS collection_to_loan_pct,
    COUNT(DISTINCT l.account_id) AS total_loan_accounts
FROM fact_loan l
LEFT JOIN fact_repayment r
    ON r.account_id = l.account_id;

-- =========================================================
-- KPI 9: PRODUCT PURPOSE / INTEREST RATE / DEFAULT ANALYSIS
-- =========================================================
SELECT
    p.purpose_category,
    COUNT(*) AS loan_accounts,
    SUM(l.loan_amount) AS total_loan_amount,
    ROUND(AVG(l.loan_amount), 2) AS average_loan_amount,
    ROUND(AVG(p.int_rate) * 100, 2) AS average_interest_rate_pct,
    ROUND(
        SUM(CASE WHEN LOWER(TRIM(l.loan_status)) = 'default' THEN 1 ELSE 0 END)
        * 100.0 / NULLIF(COUNT(*), 0),
        2
    ) AS default_rate_pct
FROM fact_loan l
JOIN dim_product p
    ON p.product_id = l.product_id
GROUP BY p.purpose_category
ORDER BY total_loan_amount DESC;

-- =========================================================
-- KPI 10: BRANCH PERFORMANCE AND DEFAULT RISK
-- =========================================================
SELECT
    b.branch_name,
    b.state_name,
    b.city,
    b.branch_performance_category,
    COUNT(*) AS loan_accounts,
    SUM(l.loan_amount) AS total_loan_amount,
    ROUND(AVG(l.loan_amount), 2) AS average_loan_amount,
    ROUND(
        SUM(CASE WHEN LOWER(TRIM(l.loan_status)) = 'default' THEN 1 ELSE 0 END)
        * 100.0 / NULLIF(COUNT(*), 0),
        2
    ) AS default_rate_pct
FROM fact_loan l
JOIN dim_branch b
    ON b.branch_id = l.branch_id
GROUP BY
    b.branch_name,
    b.state_name,
    b.city,
    b.branch_performance_category
ORDER BY total_loan_amount DESC;

-- =========================================================
-- EXTRA DATA QUALITY CHECK: LOANS WITHOUT REPAYMENT RECORDS
-- A non-zero result means some loan accounts lack repayment data.
-- =========================================================
SELECT
    COUNT(*) AS loans_without_repayment_records
FROM fact_loan l
LEFT JOIN fact_repayment r
    ON r.account_id = l.account_id
WHERE r.account_id IS NULL;

SELECT
    c.client_id,
    c.client_name,
    COUNT(l.account_id) AS total_loans,
    SUM(l.loan_amount) AS total_loan_amount
FROM dim_client c
JOIN fact_loan l
    ON c.client_id = l.client_id
GROUP BY c.client_id, c.client_name
ORDER BY total_loans DESC, total_loan_amount DESC
LIMIT 10;

-- =====================================================
-- KPI 11: OVERALL AVERAGE INTEREST RATE
-- Objective: Calculate the average interest rate across
-- all loan products available in the banking dataset.
-- Business Insight: Understand the bank's average
-- lending interest rate.
-- =====================================================

SELECT
    ROUND(AVG(int_rate) * 100, 2) AS average_interest_rate_pct
FROM dim_product;