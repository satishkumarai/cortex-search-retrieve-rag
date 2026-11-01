-- 034_governed_rls_retrieval.sql
-- Pattern 5: Post-Retrieval Caller-Rights Row Access Policy (RLS) Enforcement
-- Cortex Search runs with owner's rights; re-joining the caller's governed table/view
-- enforces dynamic Row Access Policies (RAP) in the caller's session context.

USE ROLE SEARCH_APP_USER_ROLE;
USE WAREHOUSE SEARCH_APP_WH;
USE DATABASE RETRIEVE_DEMO_DB;
USE SCHEMA KNOWLEDGE_CORPUS;

-- Step 1: Candidate retrieval via CORTEX_SEARCH_RETRIEVE
-- Returns top semantic candidates from the search index (built with owner's rights)
WITH CANDIDATES AS (
    SELECT
        cs.ARTICLE_ID,
        cs.LAST_UPDATED AS INDEXED_LAST_UPDATED,
        PARSE_JSON(cs.METADATA$RESULT_DETAIL):scores:similarity_score::FLOAT AS SIMILARITY_SCORE
    FROM TABLE(CORTEX_SEARCH_RETRIEVE(
        service_name => 'RETRIEVE_DEMO_DB.KNOWLEDGE_CORPUS.KNOWLEDGE_BASE_SEARCH_SERVICE',
        query => 'how do I configure Okta SSO SAML login and identity providers',
        limit => 6
    )) AS cs
    WHERE cs.METADATA$ERROR IS NULL
)
-- Step 2: Caller-Rights Join
-- Re-joining live KNOWLEDGE_BASE_ARTICLES in the caller's session evaluates:
-- 1. Timestamp freshness (drops stale/deleted chunks)
-- 2. Any Row Access Policies (RAP) attached to KNOWLEDGE_BASE_ARTICLES for the current role
SELECT
    a.ARTICLE_ID,
    a.ARTICLE_TITLE,
    a.CATEGORY,
    a.BODY_TEXT,
    a.LAST_UPDATED,
    c.SIMILARITY_SCORE
FROM CANDIDATES AS c
JOIN RETRIEVE_DEMO_DB.KNOWLEDGE_CORPUS.KNOWLEDGE_BASE_ARTICLES AS a
    ON a.ARTICLE_ID = c.ARTICLE_ID
   AND a.LAST_UPDATED = c.INDEXED_LAST_UPDATED
ORDER BY c.SIMILARITY_SCORE DESC NULLS LAST
LIMIT 3;
