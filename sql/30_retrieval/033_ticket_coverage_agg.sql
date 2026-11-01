-- 033_ticket_coverage_agg.sql
-- Pattern 3: Retrieval + Relational JOIN + GROUP BY Aggregations
-- Impossible with REST/Python API without pulling raw results out to an app server.

USE ROLE SEARCH_APP_USER_ROLE;
USE WAREHOUSE SEARCH_APP_WH;
USE DATABASE RETRIEVE_DEMO_DB;
USE SCHEMA KNOWLEDGE_CORPUS;

-- Calculate which KB articles cover the most open support tickets, segmented by Customer Tier
-- The index lags the base tables by up to TARGET_LAG, so re-join to the live article row:
-- matching LAST_UPDATED drops hits whose source changed (or was deleted) since indexing,
-- and title/category come from the live row rather than the index.
SELECT
    a.ARTICLE_TITLE,
    a.CATEGORY,
    c.TIER AS CUSTOMER_TIER,
    COUNT(DISTINCT t.TICKET_ID) AS TICKETS_COVERED
FROM OPEN_TICKETS AS t
JOIN CUSTOMERS AS c 
    ON t.CUSTOMER_ID = c.CUSTOMER_ID,
LATERAL CORTEX_SEARCH_RETRIEVE(
    service_name => 'RETRIEVE_DEMO_DB.KNOWLEDGE_CORPUS.KNOWLEDGE_BASE_SEARCH_SERVICE',
    query => t.ISSUE_DESCRIPTION,
    limit => 1
) AS cs
JOIN KNOWLEDGE_BASE_ARTICLES AS a
    ON a.ARTICLE_ID = cs.ARTICLE_ID
   AND a.LAST_UPDATED = cs.LAST_UPDATED
WHERE cs.METADATA$ERROR IS NULL
GROUP BY a.ARTICLE_TITLE, a.CATEGORY, c.TIER
ORDER BY TICKETS_COVERED DESC, c.TIER ASC;
