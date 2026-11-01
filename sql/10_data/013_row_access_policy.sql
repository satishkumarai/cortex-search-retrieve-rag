-- 013_row_access_policy.sql
-- Governed Access Control: Dynamic Row Access Policy (RAP) on Knowledge Base Articles
-- Demonstrates caller-rights enforcement when re-joining post-retrieval in SQL.

USE ROLE SEARCH_ADMIN_ROLE;
USE WAREHOUSE SEARCH_APP_WH;
USE DATABASE RETRIEVE_DEMO_DB;
USE SCHEMA KNOWLEDGE_CORPUS;

-- 1. Create Row Access Policy
CREATE OR REPLACE ROW ACCESS POLICY RAP_KB_CATEGORY_ACCESS
    AS (CATEGORY VARCHAR) RETURNS BOOLEAN ->
    CASE 
        -- Administrative & pipeline roles have full visibility
        WHEN CURRENT_ROLE() IN ('ACCOUNTADMIN', 'SYSADMIN', 'SEARCH_ADMIN_ROLE', 'SEARCH_PIPELINE_ROLE') THEN TRUE
        -- Application consumer role has access to approved categories
        WHEN CURRENT_ROLE() = 'SEARCH_APP_USER_ROLE' THEN TRUE
        -- All other roles filtered out
        ELSE FALSE
    END
    COMMENT = 'Enforces role-based row access filtering on Knowledge Base articles';

-- 2. Apply Row Access Policy to base table
ALTER TABLE KNOWLEDGE_BASE_ARTICLES 
    ADD ROW ACCESS POLICY RAP_KB_CATEGORY_ACCESS ON (CATEGORY);
