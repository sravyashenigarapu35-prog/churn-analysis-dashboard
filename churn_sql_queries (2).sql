-- ============================================================
-- TELECOM CUSTOMER CHURN ANALYSIS - SQL QUERIES
-- Author: Data Analyst Portfolio Project
-- Database: SQL Server / PostgreSQL compatible
-- ============================================================

-- ============================================================
-- STEP 1: CREATE DATABASE & TABLE STRUCTURE
-- ============================================================

CREATE DATABASE IF NOT EXISTS TelecomChurnDB;
USE TelecomChurnDB;

CREATE TABLE customers (
    customer_id         VARCHAR(20) PRIMARY KEY,
    gender              VARCHAR(10),
    senior_citizen      INT,
    partner             VARCHAR(5),
    dependents          VARCHAR(5),
    tenure              INT,
    phone_service       VARCHAR(5),
    multiple_lines      VARCHAR(20),
    internet_service    VARCHAR(20),
    online_security     VARCHAR(20),
    online_backup       VARCHAR(20),
    device_protection   VARCHAR(20),
    tech_support        VARCHAR(20),
    streaming_tv        VARCHAR(20),
    streaming_movies    VARCHAR(20),
    contract            VARCHAR(20),
    paperless_billing   VARCHAR(5),
    payment_method      VARCHAR(30),
    monthly_charges     DECIMAL(10,2),
    total_charges       DECIMAL(10,2),
    churn               VARCHAR(5)
);

-- ============================================================
-- STEP 2: EXPLORATORY DATA ANALYSIS (EDA) QUERIES
-- ============================================================

-- 2a. Overall churn rate
SELECT 
    churn,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM customers
GROUP BY churn;

-- 2b. Churn by contract type (this was a game-changer finding)
SELECT 
    contract,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS churn_rate
FROM customers
GROUP BY contract
ORDER BY churn_rate DESC;

-- 2c. Churn by tenure buckets
SELECT 
    CASE 
        WHEN tenure <= 6 THEN '0-6 months'
        WHEN tenure <= 12 THEN '7-12 months'
        WHEN tenure <= 24 THEN '13-24 months'
        WHEN tenure <= 48 THEN '25-48 months'
        ELSE '49-72 months'
    END AS tenure_group,
    COUNT(*) AS total,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS churn_rate
FROM customers
GROUP BY 
    CASE 
        WHEN tenure <= 6 THEN '0-6 months'
        WHEN tenure <= 12 THEN '7-12 months'
        WHEN tenure <= 24 THEN '13-24 months'
        WHEN tenure <= 48 THEN '25-48 months'
        ELSE '49-72 months'
    END
ORDER BY churn_rate DESC;

-- 2d. Revenue impact analysis
SELECT 
    churn,
    COUNT(*) AS customers,
    ROUND(AVG(monthly_charges), 2) AS avg_monthly,
    ROUND(SUM(monthly_charges), 2) AS total_monthly_revenue,
    ROUND(AVG(total_charges), 2) AS avg_lifetime_value
FROM customers
GROUP BY churn;

-- 2e. Churn by payment method
SELECT 
    payment_method,
    COUNT(*) AS total,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS churn_rate
FROM customers
GROUP BY payment_method
ORDER BY churn_rate DESC;

-- 2f. Internet service type vs churn
SELECT 
    internet_service,
    COUNT(*) AS total,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS churn_rate
FROM customers
GROUP BY internet_service
ORDER BY churn_rate DESC;

-- ============================================================
-- STEP 3: ADVANCED ANALYSIS
-- ============================================================

-- 3a. High-risk customer segments
SELECT 
    contract,
    internet_service,
    CASE WHEN tenure <= 12 THEN 'New' ELSE 'Established' END AS customer_type,
    COUNT(*) AS total,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS churn_rate,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN monthly_charges ELSE 0 END), 2) AS revenue_at_risk
FROM customers
GROUP BY contract, internet_service, 
    CASE WHEN tenure <= 12 THEN 'New' ELSE 'Established' END
HAVING COUNT(*) > 50
ORDER BY churn_rate DESC;

-- 3b. Service adoption and churn correlation
SELECT 
    (CASE WHEN online_security = 'Yes' THEN 1 ELSE 0 END +
     CASE WHEN online_backup = 'Yes' THEN 1 ELSE 0 END +
     CASE WHEN device_protection = 'Yes' THEN 1 ELSE 0 END +
     CASE WHEN tech_support = 'Yes' THEN 1 ELSE 0 END +
     CASE WHEN streaming_tv = 'Yes' THEN 1 ELSE 0 END +
     CASE WHEN streaming_movies = 'Yes' THEN 1 ELSE 0 END) AS services_count,
    COUNT(*) AS total,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS churn_rate
FROM customers
WHERE internet_service != 'No'
GROUP BY 
    (CASE WHEN online_security = 'Yes' THEN 1 ELSE 0 END +
     CASE WHEN online_backup = 'Yes' THEN 1 ELSE 0 END +
     CASE WHEN device_protection = 'Yes' THEN 1 ELSE 0 END +
     CASE WHEN tech_support = 'Yes' THEN 1 ELSE 0 END +
     CASE WHEN streaming_tv = 'Yes' THEN 1 ELSE 0 END +
     CASE WHEN streaming_movies = 'Yes' THEN 1 ELSE 0 END)
ORDER BY services_count;

-- 3c. Monthly charges distribution for churned vs retained
SELECT 
    churn,
    CASE 
        WHEN monthly_charges < 30 THEN 'Under $30'
        WHEN monthly_charges < 60 THEN '$30-$59'
        WHEN monthly_charges < 90 THEN '$60-$89'
        ELSE '$90+'
    END AS charge_bracket,
    COUNT(*) AS customer_count
FROM customers
GROUP BY churn,
    CASE 
        WHEN monthly_charges < 30 THEN 'Under $30'
        WHEN monthly_charges < 60 THEN '$30-$59'
        WHEN monthly_charges < 90 THEN '$60-$89'
        ELSE '$90+'
    END
ORDER BY churn, charge_bracket;

-- ============================================================
-- STEP 4: VIEWS FOR POWER BI
-- ============================================================

-- View: KPI Summary
CREATE VIEW vw_churn_kpis AS
SELECT
    COUNT(*) AS total_customers,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS churn_rate,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN monthly_charges ELSE 0 END), 2) AS monthly_revenue_lost,
    ROUND(AVG(CASE WHEN churn = 'No' THEN tenure END), 1) AS avg_retained_tenure,
    ROUND(AVG(CASE WHEN churn = 'Yes' THEN tenure END), 1) AS avg_churned_tenure
FROM customers;

-- View: Risk scoring for ML integration
CREATE VIEW vw_churn_risk_features AS
SELECT 
    customer_id,
    tenure,
    monthly_charges,
    total_charges,
    CASE WHEN contract = 'Month-to-month' THEN 1 ELSE 0 END AS is_month_to_month,
    CASE WHEN internet_service = 'Fiber optic' THEN 1 ELSE 0 END AS is_fiber,
    CASE WHEN online_security = 'Yes' THEN 1 ELSE 0 END AS has_security,
    CASE WHEN tech_support = 'Yes' THEN 1 ELSE 0 END AS has_tech_support,
    CASE WHEN paperless_billing = 'Yes' THEN 1 ELSE 0 END AS is_paperless,
    (CASE WHEN online_security = 'Yes' THEN 1 ELSE 0 END +
     CASE WHEN online_backup = 'Yes' THEN 1 ELSE 0 END +
     CASE WHEN device_protection = 'Yes' THEN 1 ELSE 0 END +
     CASE WHEN tech_support = 'Yes' THEN 1 ELSE 0 END) AS support_services_count,
    churn
FROM customers;
