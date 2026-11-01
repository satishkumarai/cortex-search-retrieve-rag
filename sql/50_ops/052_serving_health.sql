-- 052_serving_health.sql
-- Operational Maintenance: Serving State & Cold-Start Management

USE ROLE SEARCH_ADMIN_ROLE;
USE DATABASE RETRIEVE_DEMO_DB;
USE SCHEMA KNOWLEDGE_CORPUS;

-- Cortex Search serving automatically suspends upon prolonged inactivity to save cost.
-- The first CORTEX_SEARCH_RETRIEVE query will automatically resume serving,
-- incurring cold-start latency.

-- Proactive Warmup / Manual Resume:
-- Useful to run via scheduled task prior to high-traffic business hours.
ALTER CORTEX SEARCH SERVICE KNOWLEDGE_BASE_SEARCH_SERVICE RESUME SERVING;

-- Manual Suspend (if service is unused or undergoing maintenance):
-- ALTER CORTEX SEARCH SERVICE KNOWLEDGE_BASE_SEARCH_SERVICE SUSPEND SERVING;
