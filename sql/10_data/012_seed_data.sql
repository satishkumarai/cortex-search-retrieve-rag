-- 012_seed_data.sql
-- Representative sample data for knowledge base, customers, and open tickets

USE ROLE SEARCH_ADMIN_ROLE;
USE WAREHOUSE SEARCH_APP_WH;
USE DATABASE RETRIEVE_DEMO_DB;
USE SCHEMA KNOWLEDGE_CORPUS;

-- 1. Insert Knowledge Base Articles
INSERT OVERWRITE INTO KNOWLEDGE_BASE_ARTICLES (ARTICLE_ID, ARTICLE_TITLE, CATEGORY, BODY_TEXT, AUTHOR)
VALUES
    ('KB-101', 'Filing Employee Expense Reports', 'Finance',
     'To file an expense report, navigate to the Internal Portal > Finance > Concur. Attach all itemized receipts for expenses exceeding $25. Reports must be submitted within 30 days of the transaction date.', 'Jane Doe'),
    ('KB-102', 'Configuring SSO with Okta', 'Security',
     'Single Sign-On (SSO) integration requires SAML 2.0. Export your Okta metadata XML and import it into Admin Console > Security > Identity Providers. Enable SCIM for automated user provisioning.', 'John Smith'),
    ('KB-103', 'Troubleshooting Snowflake Warehouse Spilling', 'Engineering',
     'Warehouse spilling to remote storage occurs when query working memory is exhausted. Resolve by increasing warehouse size, reducing skew in join keys, or applying partition pruning filters.', 'Alice Johnson'),
    ('KB-104', 'Resetting VPN MFA Tokens', 'IT Support',
     'If your hardware or software MFA token is desynchronized, contact the IT Helpdesk via Slack at #it-help or submit a ticket with your corporate employee serial ID.', 'Bob Williams'),
    ('KB-105', 'Managing Snowflake Dynamic Table Lag', 'Engineering',
     'Dynamic Tables refresh automatically based on TARGET_LAG. If a dynamic table refresh fails with UPSTREAM_FAILED, inspect upstream streams and base table schema changes.', 'Alice Johnson');

-- 2. Insert Customers
INSERT OVERWRITE INTO CUSTOMERS (CUSTOMER_ID, CUSTOMER_NAME, TIER, REGION)
VALUES
    ('CUST-001', 'Acme Global Logistics', 'ENTERPRISE', 'US-EAST'),
    ('CUST-002', 'Apex Health Technologies', 'ENTERPRISE', 'EU-WEST'),
    ('CUST-003', 'Starlight Retail', 'GROWTH', 'US-WEST'),
    ('CUST-004', 'Nova Fintech', 'STANDARD', 'APAC');

-- 3. Insert Open Tickets (with sample per-row query_options using SELECT)
INSERT OVERWRITE INTO OPEN_TICKETS (TICKET_ID, CUSTOMER_ID, ISSUE_DESCRIPTION, QUERY_OPTIONS)
SELECT 'TCK-9001', 'CUST-001', 'My queries are running slow and spilling gigabytes to remote storage.', 
       PARSE_JSON('{"scoring_config": {"weights": {"texts": 2, "vectors": 1}}}')
UNION ALL
SELECT 'TCK-9002', 'CUST-002', 'Cannot submit my travel receipt for hotel reimbursement in Concur portal.', 
       PARSE_JSON('{"scoring_config": {"weights": {"texts": 1, "vectors": 2}}}')
UNION ALL
SELECT 'TCK-9003', 'CUST-003', 'Our Okta SAML assertions are failing during login with invalid cert.', 
       NULL
UNION ALL
SELECT 'TCK-9004', 'CUST-004', 'Dynamic table is stuck in refreshing state and not meeting 1 minute lag.', 
       PARSE_JSON('{"scoring_config": {"weights": {"texts": 3, "vectors": 1}}}');
