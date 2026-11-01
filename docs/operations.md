# Production Operations & Observability

## 1. Serving State Lifecycle

Cortex Search separates indexing from serving:
- **Indexing**: Triggered continuously or periodically based on `TARGET_LAG` using serverless or designated warehouse compute.
- **Serving**: An active serving cluster handles interactive vector index lookups.

### Auto-Suspend & Cold Start
- To optimize costs, Cortex Search automatically suspends its serving cluster after a period of inactivity.
- When querying a suspended service via `CORTEX_SEARCH_RETRIEVE`, the query will automatically wake up and resume serving. This introduces a one-time cold-start latency on the first request.
- **Production Best Practice**: For latency-sensitive daytime workloads, run `ALTER CORTEX SEARCH SERVICE <name> RESUME SERVING;` ahead of business hours via a Snowflake Task.

---

## 2. Per-Row Error Isolation in LATERAL Joins

When executing `CORTEX_SEARCH_RETRIEVE` inside a `LATERAL` join across multiple rows:
- If retrieval fails for an individual row (e.g. malformed filter or invalid options), that row's output populates `METADATA$ERROR`.
- **The SQL statement does not abort**; all other rows continue processing and return results normally.
- **Best Practice**: Always include `WHERE METADATA$ERROR IS NULL` for user-facing flows, and log rows where `METADATA$ERROR IS NOT NULL` to an observability table.

---

## 3. Application Runtime Operations: `search_app.py`

The reference application at `app/streamlit/search_app.py` executes directly on Snowflake compute via Snowpark Python:

### Execution Context & Privileges
- **Role**: Execute under `SEARCH_APP_USER_ROLE` or higher.
- **Compute Warehouse**: Runs lightweight SQL queries against `SEARCH_APP_WH` (`XSMALL`).
- **Session Resolution**: Uses `get_active_session()` to eliminate client credential handling.

### Operational Logging & Debugging
- Search requests capture `METADATA$REQUEST_ID` for tracing back to `SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY`.
- Reranker and vector similarity scores are surfaced from `PARSE_JSON(METADATA$RESULT_DETAIL):scores` for auditability and quality validation.

---

## 4. Owner's Rights & Caller-Level Governance (RLS / Masking)

A critical architectural property of Cortex Search:
- **Owner's Rights Execution**: Cortex Search builds and refreshes its index under the privileges of the service owner (`SEARCH_ADMIN_ROLE`). Any data the owner can `SELECT` at refresh time is included in the index.
- **No Dynamic RLS at Index Time**: When an end-user queries the service with `USAGE` privileges, the underlying search index does *not* dynamically re-evaluate the caller's Row Access Policies (RAP) or dynamic column masking rules.

### Enterprise Governance Patterns
1. **Domain Isolation (RBAC)**: Create dedicated search services for restricted security domains (e.g., `HR_CONFIDENTIAL_SEARCH_SERVICE` vs `PUBLIC_KB_SEARCH_SERVICE`) and restrict `GRANT USAGE` by role.
2. **Post-Retrieval RLS Enforcement (SQL-Native)**:
   - Because `CORTEX_SEARCH_RETRIEVE` is a SQL table function evaluated inside the caller's query session, you can inner-join candidate `ARTICLE_ID`s back to the caller's governed base table or view.
   - If the caller's role is restricted by a Row Access Policy on the base table, the join automatically returns `0 rows`, dropping unauthorized candidates before context reaches the LLM prompt.

---

## 5. Observability Queries

Inspect index refresh health and latency:
```sql
SELECT
    NAME,
    DATA_TIMESTAMP,
    STATE,
    ERROR,
    REFRESH_TRIGGER
FROM TABLE(INFORMATION_SCHEMA.CORTEX_SEARCH_REFRESH_HISTORY(
    NAME => 'RETRIEVE_DEMO_DB.KNOWLEDGE_CORPUS.KNOWLEDGE_BASE_SEARCH_SERVICE'
))
ORDER BY DATA_TIMESTAMP DESC;
```
