-- 001_roles_and_grants.sql
-- Principle of Least Privilege: Separation of duties between Admin, Service Pipeline, and Consumer roles.

USE ROLE SECURITYADMIN;

-- 1. Create functional roles
CREATE ROLE IF NOT EXISTS SEARCH_ADMIN_ROLE
    COMMENT = 'Owns databases, schemas, and Cortex Search Services';

CREATE ROLE IF NOT EXISTS SEARCH_PIPELINE_ROLE
    COMMENT = 'Service account role for refreshing/updating search service and staging data';

CREATE ROLE IF NOT EXISTS SEARCH_APP_USER_ROLE
    COMMENT = 'Application role executing low-latency SQL retrieval and RAG';

-- 2. Build role hierarchy
GRANT ROLE SEARCH_APP_USER_ROLE TO ROLE SEARCH_PIPELINE_ROLE;
GRANT ROLE SEARCH_PIPELINE_ROLE TO ROLE SEARCH_ADMIN_ROLE;
GRANT ROLE SEARCH_ADMIN_ROLE TO ROLE SYSADMIN;

-- 3. Grant roles to current user for local testing/deployment
GRANT ROLE SEARCH_ADMIN_ROLE TO USER CURRENT_USER();
GRANT ROLE SEARCH_APP_USER_ROLE TO USER CURRENT_USER();
