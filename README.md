# cortex-search-retrieve-rag

A production-grade, Google-style repository demonstrating SQL-native semantic search and Retrieval-Augmented Generation (RAG) using Snowflake's `CORTEX_SEARCH_RETRIEVE` table function (Public Preview, Oct 23, 2026).

## Overview

Historically, querying a Cortex Search service required an external client tier (REST API or Python SDK) to fetch semantic search results, followed by application-side joins against relational operational data.

With `CORTEX_SEARCH_RETRIEVE`, Cortex Search is invokable directly inside Snowflake SQL statements. It returns a relational table structure that can be:
- Queried ad-hoc for low-latency interactive search bars
- Joined via `LATERAL` across rows of incoming tickets, logs, or questions
- Combined with standard SQL operations (`JOIN`, `GROUP BY`, `QUALIFY`, `WINDOW`)
- Guarded against index lag (`TARGET_LAG`) by re-joining live base tables on `LAST_UPDATED` timestamps
- Piped directly into `AI_COMPLETE` without external orchestration

## Production Pattern: Handling Index Freshness & Target Lag

A Cortex Search Service refreshes asynchronously on its configured `TARGET_LAG` (e.g. `1 hour`), while operational tables are real-time. If base rows are updated or deleted between index refreshes, search output can return stale metadata or deleted documents.

To ensure consistency across relational joins and LLM prompts:
1. **Index Timestamps**: Pass `LAST_UPDATED` in the source query of `CREATE CORTEX SEARCH SERVICE`.
2. **Re-Join on Freshness**: Re-join the live base table on both `PRIMARY_KEY` and `LAST_UPDATED`:
   ```sql
   JOIN KNOWLEDGE_BASE_ARTICLES AS a
       ON a.ARTICLE_ID = cs.ARTICLE_ID
      AND a.LAST_UPDATED = cs.LAST_UPDATED
   ```
3. **Over-fetch and Trim**: Over-fetch search chunks (e.g. `limit => top_k * 2`) and trim post-join with `QUALIFY RANK <= top_k` so dropped stale chunks do not starve recall.
4. **Automatic Deletion Purging**: Inner-joining the live table automatically purges chunks for records deleted since the last index refresh.

## Governance Pattern: Owner's Rights & Post-Retrieval RLS

Cortex Search builds indices with **owner's rights**. When end-users query the service via `USAGE` privileges, source-table Row Access Policies (RAP) are not dynamically evaluated at search time.

To enforce caller-level access control:
- **Domain Services**: Isolate sensitive corpuses into separate search services with RBAC grants.
- **Post-Retrieval RLS (Pattern 5 / `034_governed_rls_retrieval.sql`)**: Inner-join search candidate IDs against the caller's governed base table or secure view. The caller's Row Access Policy dynamically filters unauthorized rows out of the result before LLM synthesis.

## Repository Structure

```
.
├── README.md                          # Repository overview & quickstart
├── docs/
│   ├── architecture.md                # System design & before/after architecture
│   ├── security.md                    # RBAC model & least-privilege matrix
│   ├── operations.md                  # Serving lifecycle & observability
│   ├── decision-guide.md              # RETRIEVE vs BATCH vs REST/Python API
│   └── medium_article.md              # Practitioner-led Snowflake Chronicles article
├── sql/
│   ├── 00_setup/                      # Provisioning: roles, database, schema, compute
│   │   ├── 001_roles_and_grants.sql
│   │   ├── 002_database_schema.sql
│   │   └── 003_warehouse_and_monitor.sql
│   ├── 10_data/                       # Operational & knowledge base data layer
│   │   ├── 011_tables.sql
│   │   └── 012_seed_data.sql
│   ├── 20_search/                     # Cortex Search service definitions & scoring profiles
│   │   ├── 021_cortex_search_service.sql
│   │   └── 022_scoring_profile.sql
│   ├── 30_retrieval/                  # Retrieval patterns (single query, lateral join, aggregations, RLS)
│   │   ├── 031_single_query.sql
│   │   ├── 032_lateral_enrichment.sql
│   │   ├── 033_ticket_coverage_agg.sql
│   │   └── 034_governed_rls_retrieval.sql
│   ├── 40_rag/                        # SQL-native RAG pipeline using AI_COMPLETE
│   │   └── 041_rag_answer.sql
│   └── 50_ops/                        # Telemetry, error rates, and serving health
│       ├── 051_monitoring.sql
│       └── 052_serving_health.sql
├── app/
│   └── streamlit/
│       └── search_app.py              # Snowpark Python client executing search & RAG
├── ops/
│   └── alerts.sql                     # Production monitoring alerts
└── ci/
    └── validate.sh                    # Automated verification script
```

## Quickstart

### Prerequisites
- Snowflake account with Cortex Search enabled (Public Preview in all Cortex Search regions)
- Role with permissions to create Databases, Schemas, Warehouses, and Cortex Search Services (e.g., `ACCOUNTADMIN` or `SYSADMIN`)

### Execution Order
1. Execute `sql/00_setup/` to create RBAC roles and database objects.
2. Execute `sql/10_data/` to initialize sample customer, ticket, and article tables.
3. Execute `sql/20_search/` to build the `KNOWLEDGE_BASE_SEARCH_SERVICE`.
4. Run sample workloads in `sql/30_retrieval/` and `sql/40_rag/`.
5. Run `app/streamlit/search_app.py` or deploy operational alerts in `ops/alerts.sql`.

---

## Running the Application Client (`app/streamlit/search_app.py`)

The script `app/streamlit/search_app.py` provides an end-to-end Snowpark Python driver for interactive semantic retrieval and generative RAG.

### Running in Snowsight Workspaces
1. Open `app/streamlit/search_app.py` in your Snowflake Workspace.
2. Ensure your active warehouse is set (e.g., `SEARCH_APP_WH` or `COMPUTE_WH`).
3. Click **Run** to execute the script against your live Cortex Search service.

```python
from snowflake.snowpark.context import get_active_session

# Executes semantic retrieval via CORTEX_SEARCH_RETRIEVE and generates answers with AI_COMPLETE
run_search_and_rag("How do I fix Okta SAML login errors?", category_filter="Security", top_k=2)
```

### Running CI Validation
To verify all SQL templates and directory paths:
```bash
bash ci/validate.sh
```
