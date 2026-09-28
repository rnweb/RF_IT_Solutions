# Prompt 1 — Workspace Initialization & Cloning

> You are an expert Snowflake Data Architect preparing a highly regulated banking
> demonstration. Clone the following Snowflake Quickstart repositories to the local
> workspace: [Insert Repo URLs for Snowpark, Cortex, Governance]. Once cloned, analyze
> the SQL setup files in each repository. Identify all hardcoded Database, Schema, and
> Role names. Do not execute anything yet; output a mapping table showing the original
> names and your proposed banking-specific names (e.g., `DEMO_DB` ->
> `SUPERINTENDENCY_DEMO_DB`).

## Target Quickstarts

| Area | Repository |
|------|------------|
| Data Engineering / Lakehouse | `github.com/Snowflake-Labs/sfguide-getting-started-snowpark-python` (or the data engineering guide) |
| dbt | `github.com/Snowflake-Labs/sfguide-dbt-snowflake-*` |
| Cortex AI / RAG | `github.com/Snowflake-Labs/sfguide-cortex-*` |
| Data Governance | `github.com/Snowflake-Labs/sfguide-*governance*` |

Clone destination: `snowflake-platform-demo/quickstarts/` (cloned content is git-ignored).

## Expected Output

1. Cloned repositories under `quickstarts/`.
2. A mapping table of every hardcoded Database / Schema / Role / Warehouse found in SQL
   and Python files, written into `snowflake-platform-demo/naming-conventions.md`.
3. **No execution** — read-only analysis at this stage.
