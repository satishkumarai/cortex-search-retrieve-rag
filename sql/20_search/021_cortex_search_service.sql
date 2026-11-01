-- 021_cortex_search_service.sql
-- Create Cortex Search Service over Knowledge Base Articles

USE ROLE SEARCH_ADMIN_ROLE;
USE WAREHOUSE SEARCH_APP_WH;
USE DATABASE RETRIEVE_DEMO_DB;
USE SCHEMA KNOWLEDGE_CORPUS;

-- Cortex Search Service indexing BODY_TEXT with CATEGORY as filter attribute
CREATE OR REPLACE CORTEX SEARCH SERVICE KNOWLEDGE_BASE_SEARCH_SERVICE
    ON BODY_TEXT
    ATTRIBUTES CATEGORY, ARTICLE_ID, ARTICLE_TITLE, AUTHOR
    WAREHOUSE = SEARCH_APP_WH
    TARGET_LAG = '1 hour'
    COMMENT = 'Semantic and keyword search index over knowledge base documentation'
    AS (
        SELECT
            ARTICLE_ID,
            ARTICLE_TITLE,
            CATEGORY,
            BODY_TEXT,
            AUTHOR,
            LAST_UPDATED
        FROM KNOWLEDGE_BASE_ARTICLES
    );

-- Grant USAGE to consumer application role
GRANT USAGE ON CORTEX SEARCH SERVICE KNOWLEDGE_BASE_SEARCH_SERVICE TO ROLE SEARCH_APP_USER_ROLE;
