-- ops/alerts.sql
-- Production Alerts for Cortex Search Service Health

USE ROLE SEARCH_ADMIN_ROLE;
USE DATABASE RETRIEVE_DEMO_DB;
USE SCHEMA KNOWLEDGE_CORPUS;

-- Alert 1: Notify on Cortex Search Service refresh failures
CREATE OR REPLACE ALERT ALERT_SEARCH_REFRESH_FAILURE
    WAREHOUSE = SEARCH_APP_WH
    SCHEDULE = '15 MINUTE'
    IF (EXISTS (
        SELECT 1
        FROM TABLE(INFORMATION_SCHEMA.CORTEX_SEARCH_REFRESH_HISTORY(
            NAME => 'RETRIEVE_DEMO_DB.KNOWLEDGE_CORPUS.KNOWLEDGE_BASE_SEARCH_SERVICE'
        ))
        WHERE STATE = 'FAILED'
          AND DATA_TIMESTAMP > DATEADD(minute, -15, CURRENT_TIMESTAMP())
    ))
    THEN
        CALL SYSTEM$SEND_EMAIL(
            'DATA_PLATFORM_EMAIL_INTEGRATION',
            'data-platform-alerts@example.com',
            'CRITICAL: Cortex Search Service Refresh Failed',
            'The knowledge base search service failed to refresh within the last 15 minutes.'
        );

-- Suspend alert by default until email integration is configured
ALTER ALERT ALERT_SEARCH_REFRESH_FAILURE SUSPEND;
