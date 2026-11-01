-- 032_lateral_enrichment.sql
-- Pattern 2: LATERAL Join Semantic Enrichment
-- Executes semantic retrieval once per input row from a source table.

USE ROLE SEARCH_APP_USER_ROLE;
USE WAREHOUSE SEARCH_APP_WH;
USE DATABASE RETRIEVE_DEMO_DB;
USE SCHEMA KNOWLEDGE_CORPUS;

-- Match every open ticket to its top 2 most relevant knowledge base articles
-- Inner joins live KNOWLEDGE_BASE_ARTICLES on LAST_UPDATED to guard against index lag
SELECT
    t.TICKET_ID,
    t.CUSTOMER_ID,
    t.ISSUE_DESCRIPTION,
    a.ARTICLE_ID,
    a.ARTICLE_TITLE,
    a.CATEGORY,
    a.BODY_TEXT,
    a.LAST_UPDATED,
    cs.METADATA$ERROR,
    PARSE_JSON(cs.METADATA$RESULT_DETAIL):scores AS MATCH_SCORE
FROM OPEN_TICKETS AS t,
LATERAL CORTEX_SEARCH_RETRIEVE(
    service_name => 'RETRIEVE_DEMO_DB.KNOWLEDGE_CORPUS.KNOWLEDGE_BASE_SEARCH_SERVICE',
    query => t.ISSUE_DESCRIPTION,
    limit => 2
) AS cs
JOIN KNOWLEDGE_BASE_ARTICLES AS a
    ON a.ARTICLE_ID = cs.ARTICLE_ID
   AND a.LAST_UPDATED = cs.LAST_UPDATED
WHERE cs.METADATA$ERROR IS NULL;
