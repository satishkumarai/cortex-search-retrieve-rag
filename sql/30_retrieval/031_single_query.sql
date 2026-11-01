-- 031_single_query.sql
-- Pattern 1: Single Ad-Hoc Low-Latency Search Query
-- Used by real-time search bars, in-app lookups, and single-prompt context fetch.

USE ROLE SEARCH_APP_USER_ROLE;
USE WAREHOUSE SEARCH_APP_WH;
USE DATABASE RETRIEVE_DEMO_DB;
USE SCHEMA KNOWLEDGE_CORPUS;

-- Fetch top 3 relevant articles with category filter and freshness verification
-- Over-fetches from search index (limit 6) and re-joins live KNOWLEDGE_BASE_ARTICLES on LAST_UPDATED
-- to discard stale chunks if the source article modified/deleted before index refresh.
SELECT
    a.ARTICLE_ID,
    a.ARTICLE_TITLE,
    a.CATEGORY,
    a.BODY_TEXT,
    a.LAST_UPDATED,
    cs.METADATA$REQUEST_ID,
    cs.METADATA$ERROR,
    PARSE_JSON(cs.METADATA$RESULT_DETAIL):scores AS SCORES
FROM TABLE(CORTEX_SEARCH_RETRIEVE(
    service_name => 'RETRIEVE_DEMO_DB.KNOWLEDGE_CORPUS.KNOWLEDGE_BASE_SEARCH_SERVICE',
    query => 'how do I file an expense report for my hotel stay',
    filter => OBJECT_CONSTRUCT('@eq', OBJECT_CONSTRUCT('CATEGORY', 'Finance')),
    limit => 6,
    options => OBJECT_CONSTRUCT('scoring_config', OBJECT_CONSTRUCT('weights', OBJECT_CONSTRUCT('texts', 1, 'vectors', 2)))
)) AS cs
JOIN KNOWLEDGE_BASE_ARTICLES AS a
    ON a.ARTICLE_ID = cs.ARTICLE_ID
   AND a.LAST_UPDATED = cs.LAST_UPDATED
WHERE cs.METADATA$ERROR IS NULL
LIMIT 3;
