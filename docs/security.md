# Security & Governance Architecture

## 1. Access Control Matrix

The platform enforces strict role separation using standard Snowflake Discretionary Access Control (DAC) and Role-Based Access Control (RBAC):

| Role | Object | Privilege | Justification |
| :--- | :--- | :--- | :--- |
| `SEARCH_ADMIN_ROLE` | Database / Schema | `ALL PRIVILEGES` | Object lifecycle management and schema ownership |
| `SEARCH_ADMIN_ROLE` | Cortex Search Service | `ALL PRIVILEGES` | Service creation, schema alteration, and scoring configuration |
| `SEARCH_PIPELINE_ROLE` | Source Tables | `SELECT`, `INSERT`, `UPDATE` | ETL/ELT pipelines updating corpus documents |
| `SEARCH_APP_USER_ROLE` | Database / Schema | `USAGE` | Object resolution |
| `SEARCH_APP_USER_ROLE` | Query Warehouse | `USAGE` | SQL execution compute |
| `SEARCH_APP_USER_ROLE` | Cortex Search Service | `USAGE` | Required to query via `CORTEX_SEARCH_RETRIEVE` |
| `SEARCH_APP_USER_ROLE` | Source / Dim Tables | `SELECT` | Required to join against tickets, customers, and dimension data |

## 2. Key Security Principles

1. **Zero External Data Egress**: All retrieval and generation stays inside the Snowflake security boundary. Documents never leave the customer's cloud boundary to external third-party vector databases.
2. **Unified Audit Trail**: Every call to `CORTEX_SEARCH_RETRIEVE` is assigned a unique `METADATA$REQUEST_ID` and is logged in `ACCESS_HISTORY` and `QUERY_HISTORY`.
3. **No Vector Exposure**: Vector embeddings are maintained internally by Cortex Search and are not returned to client applications, reducing attack surfaces for vector inversion attacks.
