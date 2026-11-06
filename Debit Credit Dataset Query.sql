-- =====================================================
-- BANKING TRANSACTIONS PROJECT
-- STEP 1: DATABASE AND TABLE VERIFICATION
-- =====================================================

-- Select the project database
USE `debit credit data`;

-- Verify selected database
SELECT DATABASE() AS selected_database;

-- Display all available tables
SHOW TABLES;

-- =====================================================
-- STEP 2: VERIFY BANKING DATA TABLE STRUCTURE
-- =====================================================

USE `debit credit data`;

-- Inspect all columns and their data types

DESCRIBE `copy of debit and credit banking_data`;

-- =====================================================
-- DATA VALIDATION 1: TOTAL IMPORTED RECORDS
-- Objective: Verify the number of imported transactions.
-- Expected records: 100,000
-- =====================================================

SELECT
    COUNT(*) AS total_records
FROM `copy of debit and credit banking_data`;

-- =====================================================
-- KPI 1: OVERALL TRANSACTION PERFORMANCE
-- Objective:
-- Calculate total transactions, unique customers,
-- total transaction value and average transaction value.
-- =====================================================

SELECT
    COUNT(*) AS total_transactions,

    COUNT(DISTINCT `Customer ID`) AS unique_customers,

    ROUND(SUM(Amount), 2) AS total_transaction_value,

    ROUND(AVG(Amount), 2) AS average_transaction_value

FROM `copy of debit and credit banking_data`;

-- =====================================================
-- KPI 2: CREDIT VS DEBIT ANALYSIS
-- Objective:
-- Compare transaction count, total amount,
-- average amount and percentage contribution.
-- =====================================================

SELECT
    `Transaction Type`,

    COUNT(*) AS total_transactions,

    ROUND(SUM(Amount), 2) AS total_amount,

    ROUND(AVG(Amount), 2) AS average_amount,

    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*)
         FROM `copy of debit and credit banking_data`),
        2
    ) AS transaction_percentage

FROM `copy of debit and credit banking_data`

GROUP BY `Transaction Type`

ORDER BY total_amount DESC;

-- =====================================================
-- KPI 3: NET CREDIT-DEBIT DIFFERENCE
-- Objective:
-- Calculate total credits minus total debits.
-- Positive value means credits exceed debits.
-- =====================================================

SELECT

    ROUND(
        SUM(
            CASE
                WHEN `Transaction Type` = 'Credit'
                THEN Amount
                ELSE 0
            END
        ), 2
    ) AS total_credit,

    ROUND(
        SUM(
            CASE
                WHEN `Transaction Type` = 'Debit'
                THEN Amount
                ELSE 0
            END
        ), 2
    ) AS total_debit,

    ROUND(
        SUM(
            CASE
                WHEN `Transaction Type` = 'Credit'
                THEN Amount

                WHEN `Transaction Type` = 'Debit'
                THEN -Amount

                ELSE 0
            END
        ), 2
    ) AS net_difference

FROM `copy of debit and credit banking_data`;

-- =====================================================
-- KPI 4: BANK-WISE TRANSACTION PERFORMANCE
-- Objective:
-- Compare transaction volume, unique customers,
-- total transaction value and average transaction value
-- across all banks.
-- =====================================================

SELECT

    `Bank Name`,

    COUNT(*) AS total_transactions,

    COUNT(DISTINCT `Customer ID`) AS unique_customers,

    ROUND(SUM(Amount), 2) AS total_transaction_value,

    ROUND(AVG(Amount), 2) AS average_transaction_value

FROM `copy of debit and credit banking_data`

GROUP BY `Bank Name`

ORDER BY total_transaction_value DESC;

-- =====================================================
-- KPI 5: BRANCH-WISE TRANSACTION PERFORMANCE
-- Objective:
-- Compare transaction volume, total value
-- and average transaction value across branches.
-- =====================================================

SELECT

    Branch,

    COUNT(*) AS total_transactions,

    COUNT(DISTINCT `Customer ID`) AS unique_customers,

    ROUND(SUM(Amount), 2) AS total_transaction_value,

    ROUND(AVG(Amount), 2) AS average_transaction_value

FROM `copy of debit and credit banking_data`

GROUP BY Branch

ORDER BY total_transaction_value DESC;

-- =====================================================
-- KPI 6: TRANSACTION METHOD ANALYSIS
-- Objective:
-- Analyse transaction count, total value
-- and average transaction amount by payment method.
-- =====================================================

SELECT

    `Transaction Method`,

    COUNT(*) AS total_transactions,

    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*)
         FROM `copy of debit and credit banking_data`),
        2
    ) AS transaction_percentage,

    ROUND(SUM(Amount), 2) AS total_transaction_value,

    ROUND(AVG(Amount), 2) AS average_transaction_value

FROM `copy of debit and credit banking_data`

GROUP BY `Transaction Method`

ORDER BY total_transactions DESC;

-- =====================================================
-- KPI 7: MONTHLY TRANSACTION TRENDS
-- Objective:
-- Analyse monthly credit and debit transactions,
-- transaction volume and monetary value.
-- =====================================================

SELECT

    DATE_FORMAT(
        STR_TO_DATE(`Transaction Date`, '%Y-%m-%d'),
        '%Y-%m'
    ) AS transaction_month,

    `Transaction Type`,

    COUNT(*) AS total_transactions,

    ROUND(SUM(Amount), 2) AS total_transaction_value,

    ROUND(AVG(Amount), 2) AS average_transaction_value

FROM `copy of debit and credit banking_data`

GROUP BY

    DATE_FORMAT(
        STR_TO_DATE(`Transaction Date`, '%Y-%m-%d'),
        '%Y-%m'
    ),

    `Transaction Type`

ORDER BY

    transaction_month,

    `Transaction Type`;
    
    -- =====================================================
-- DATA VALIDATION 3: TRANSACTION CATEGORIES
-- Objective: Identify Credit and Debit transaction counts.
-- =====================================================

SELECT
    `Transaction Type`,
    COUNT(*) AS transaction_count
FROM `copy of debit and credit banking_data`
GROUP BY `Transaction Type`;