# Naming Conventions — Banking Persona Mapping

Proposed mapping of generic Quickstart objects to the banking demo persona.
**Status: pending approval** — the agent must not execute refactoring until this table is signed off.

Prefix standard: all demo objects use the `BANKING_DEMO_` prefix to avoid collisions with
existing objects in the Snowflake tenant.

## Databases

| Original (Quickstart) | Banking Persona | Notes |
|-----------------------|-----------------|-------|
| `QUICKSTART_DB` | `BANKING_DEMO_DB` | Main demo database |
| `DEMO_DB` | `SUPERINTENDENCY_DEMO_DB` | Alternate proposal if a single consolidated DB is preferred |
| `SNOWFLAKE_SAMPLE_DATA` | _(unchanged)_ | Public sample data — read-only |

## Schemas

| Original | Banking Persona |
|----------|-----------------|
| `RAW` | `RAW` |
| `STAGING` | `STAGING` |
| `ANALYTICS` | `ANALYTICS` |
| `ML` | `ML` |
| `GOVERNANCE` | `GOVERNANCE` |

## Warehouses

| Original | Banking Persona | Size |
|----------|-----------------|------|
| `COMPUTE_WH` | `BANKING_DEMO_WH` | X-Small (default) |
| `TRANSFORM_WH` | `BANKING_DEMO_TRANSFORM_WH` | X-Small |
| `ML_WH` | `BANKING_DEMO_ML_WH` | Small |
| `STREAMLIT_WH` | `BANKING_DEMO_APP_WH` | X-Small |

## Roles

| Original | Banking Persona | Scope |
|----------|-----------------|-------|
| `ACCOUNTADMIN` | _(never used directly by agent)_ | — |
| `SYSADMIN` | `BANKING_DEMO_SYSADMIN` | Owns demo DBs/warehouses |
| `SECURITYADMIN` | `BANKING_DEMO_SECURITYADMIN` | Owns grants/policies |
| `BI_ANALYST` | `BANKING_DEMO_BI_ANALYST` | Masked read access |
| `ENGINEER` | `BANKING_DEMO_ENGINEER` | Ingestion & transformation |

## Tables & Columns (semantic translation)

| Original | Banking Persona |
|----------|-----------------|
| `RETAIL_SALES` | `CREDIT_CARD_TRANSACTIONS` |
| `CUSTOMERS` | `CUSTOMERS` |
| `SSN` | `NATIONAL_ID` |
| `CREDIT_CARD` | `CREDIT_CARD_NUMBER` |
| `PRODUCTS` | `BANKING_PRODUCTS` |

## Session Contexts

| Original | Banking Persona |
|----------|-----------------|
| `SALES_DB.PUBLIC` | `BANKING_DEMO_DB.RAW` |
| Retail/GDP demo data | Financial/banking datasets (transactions, customers, regulatory docs) |
