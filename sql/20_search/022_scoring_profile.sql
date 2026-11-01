-- 022_scoring_profile.sql
-- Configure Named Scoring Profiles for Cortex Search Service
-- Demonstrates hybrid search weighting and reranker integration

USE ROLE SEARCH_ADMIN_ROLE;
USE DATABASE RETRIEVE_DEMO_DB;
USE SCHEMA KNOWLEDGE_CORPUS;

-- Optional: Add a named scoring profile to customize ranking presets
-- (e.g. emphasizing vector semantic similarity over exact text keyword matches)
-- Note: Requires Cortex Search Service support for scoring profiles.

/*
ALTER CORTEX SEARCH SERVICE KNOWLEDGE_BASE_SEARCH_SERVICE
ADD SCORING PROFILE SEMANTIC_HEAVY
    CONFIG = '{"weights": {"texts": 1, "vectors": 3}}';
*/
