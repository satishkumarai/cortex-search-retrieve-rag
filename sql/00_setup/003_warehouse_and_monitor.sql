-- 003_warehouse_and_monitor.sql
-- Dedicated query warehouse with aggressive auto-suspend and a Resource Monitor

USE ROLE ACCOUNTADMIN;

-- 1. Create Resource Monitor for query warehouse cost safety
CREATE RESOURCE MONITOR IF NOT EXISTS RM_SEARCH_APP
    WITH CREDIT_QUOTA = 50
    FREQUENCY = MONTHLY
    START_TIMESTAMP = IMMEDIATELY
    TRIGGERS 
        ON 80 PERCENT DO NOTIFY
        ON 100 PERCENT DO SUSPEND;

USE ROLE SYSADMIN;

-- 2. Create interactive query warehouse
-- Note: CORTEX_SEARCH_RETRIEVE uses the Cortex Search service's internal serving compute
-- for indexing/vectors, but the surrounding SQL statement consumes warehouse compute.
CREATE WAREHOUSE IF NOT EXISTS SEARCH_APP_WH
    WITH WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    MIN_CLUSTER_COUNT = 1
    MAX_CLUSTER_COUNT = 2
    SCALING_POLICY = 'STANDARD'
    RESOURCE_MONITOR = RM_SEARCH_APP
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Virtual warehouse for running CORTEX_SEARCH_RETRIEVE SQL queries';

GRANT USAGE ON WAREHOUSE SEARCH_APP_WH TO ROLE SEARCH_APP_USER_ROLE;
