# Naming Conventions — Banking Persona Mapping

**Status: APPROVED** — this is the single source of truth for object naming.
All SQL/Python assets must use these names. Originals in `quickstarts/` stay untouched
(cloned repos are immutable source of truth; refactored copies live in `scripts/`).

## Approved Mapping

| Generic Quickstart Object | Banking Demo Target | Purpose / Justification |
| :--- | :--- | :--- |
| `QUICKSTART_DB` / `DEMO_DB` | `SUPERINTENDENCY_DEMO_DB` | Primary database housing all session assets. |
| `RETAIL_SCHEMA` / `SALES` | `CORE_BANKING_SCHEMA` | Raw ingestion layer for transactional data. |
| `ANALYTICS_SCHEMA` | `RISK_ANALYTICS_SCHEMA` | Transformed layer for BI, RLS, and Cortex. |
| `CUSTOMER_TABLE` | `CLIENT_PROFILE_DIM` | Target for Dynamic Data Masking (SSN/National ID). |
| `ORDERS_TABLE` | `CREDIT_CARD_TRANSACTIONS` | High-volume transactional fact table. |
| `DATA_ENGINEER_ROLE` | `FR_DATA_ENGINEER` | Functional role mapping for pipeline creation. |
| `ANALYST_ROLE` | `FR_BI_ANALYST` | Functional role to test masking policies (masked view). |
| `COMPUTE_WH` | `WH_INGESTION_XSMALL` | Compute dedicated to Snowpipe and dbt runs. |
| `ANALYTICS_WH` | `WH_CORTEX_LARGE` | Compute allocated for ML and Cortex LLM queries. |

## Derived Objects — PROVISIONAL (pending approval)

Required to complete `scripts/00_foundation.sql`; not covered by the approved table.
Flagged as provisional wherever they appear in scripts.

| Generic / Need | Proposed Target | Purpose / Justification |
| :--- | :--- | :--- |
| dbt intermediate layer | `STAGING_SCHEMA` | dbt requires a staging schema between raw and analytics. |
| Policies & mapping tables | `GOVERNANCE_SCHEMA` | Masking/row-access policies and role-mapping tables (Session 3). |
| Agent-scoped admin role | `FR_DEMO_ADMIN` | Scoped replacement for ACCOUNTADMIN per security guardrails. |
| Streamlit compute | `WH_APP_XSMALL` | Session 2 app compute, separated from WH_CORTEX_LARGE. |

> Machine-learning artifacts (feature tables, trained models, embeddings) live in
> `RISK_ANALYTICS_SCHEMA` — covered by the approved "BI, RLS, and Cortex" purpose.

## Usage Rules

1. **Never** reference `QUICKSTART_*`, `DEMO_*`, `RETAIL_*`, `ANALYTICS_WH`, etc. in
   project scripts.
2. Every object name in `scripts/*.sql` comes from the `PARAMETERS` block of
   [`00_foundation.sql`](scripts/00_foundation.sql) — change names there, nowhere else.
3. Functional roles use the `FR_` prefix; compute uses the `WH_` prefix; database and
   schema names are uppercase with underscores.
