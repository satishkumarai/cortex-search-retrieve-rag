-- 041_rag_answer.sql
-- Pattern 4: End-to-End SQL-Native RAG Pipeline
-- Retrieves context via CORTEX_SEARCH_RETRIEVE, aggregates snippets, and generates answers with AI_COMPLETE.

USE ROLE SEARCH_APP_USER_ROLE;
USE WAREHOUSE SEARCH_APP_WH;
USE DATABASE RETRIEVE_DEMO_DB;
USE SCHEMA KNOWLEDGE_CORPUS;

WITH USER_QUERY AS (
    SELECT 'My Okta SSO SAML login is failing with invalid certificate' AS QUESTION
),
RAW_CHUNKS AS (
    SELECT
        q.QUESTION,
        cs.ARTICLE_ID,
        cs.LAST_UPDATED AS INDEXED_LAST_UPDATED,
        PARSE_JSON(cs.METADATA$RESULT_DETAIL):scores:similarity_score::FLOAT AS SIMILARITY_SCORE
    FROM USER_QUERY AS q,
    LATERAL CORTEX_SEARCH_RETRIEVE(
        service_name => 'RETRIEVE_DEMO_DB.KNOWLEDGE_CORPUS.KNOWLEDGE_BASE_SEARCH_SERVICE',
        query => q.QUESTION,
        limit => 6
    ) AS cs
    WHERE cs.METADATA$ERROR IS NULL
),
FRESH_CHUNKS AS (
    SELECT
        r.QUESTION,
        a.ARTICLE_TITLE,
        a.BODY_TEXT,
        ROW_NUMBER() OVER (ORDER BY r.SIMILARITY_SCORE DESC NULLS LAST) AS RANK
    FROM RAW_CHUNKS AS r
    JOIN KNOWLEDGE_BASE_ARTICLES AS a
        ON a.ARTICLE_ID = r.ARTICLE_ID
       AND a.LAST_UPDATED = r.INDEXED_LAST_UPDATED
    QUALIFY RANK <= 3
),
CONTEXT_BUNDLE AS (
    SELECT
        QUESTION,
        LISTAGG(
            '[' || RANK || '] ' || ARTICLE_TITLE || ':\n' || BODY_TEXT,
            '\n\n'
        ) WITHIN GROUP (ORDER BY RANK) AS RETRIEVED_CONTEXT
    FROM FRESH_CHUNKS
    GROUP BY QUESTION
)
SELECT
    QUESTION,
    RETRIEVED_CONTEXT,
    AI_COMPLETE(
        'llama3.1-70b',
        CONCAT(
            'You are an expert enterprise IT support assistant. Answer the user question accurately using only the provided context snippets.\n\n',
            'Context:\n', RETRIEVED_CONTEXT, '\n\n',
            'Question: ', QUESTION, '\n\n',
            'Answer:'
        )
    ) AS GENERATED_ANSWER
FROM CONTEXT_BUNDLE;
