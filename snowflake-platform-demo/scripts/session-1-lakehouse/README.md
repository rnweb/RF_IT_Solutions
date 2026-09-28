# Session 1 — Lakehouse & Data Engineering

Assets for the first demonstration session.

## Scope

- External stage + Snowpipe configuration pulling public financial datasets (AWS S3/GCS)
- Raw landing zone in `SUPERINTENDENCY_DEMO_DB.CORE_BANKING_SCHEMA`
  (`CREDIT_CARD_TRANSACTIONS`, `CLIENT_PROFILE_DIM`)
- dbt project initialization with automated `profiles.yml`
- `dbt build` populating `STAGING_SCHEMA` → `RISK_ANALYTICS_SCHEMA`

## Planned Files

| File | Purpose |
|------|---------|
| `01_stage_setup.sql` | External stage + file format definitions |
| `02_snowpipe_setup.sql` | Snowpipe pipes with auto-ingest |
| `03_sample_data_load.sql` | Initial backfill of raw tables |
| `dbt/` | dbt project (models for staging → analytics) |

## Prerequisites

- `scripts/00_foundation.sql` executed successfully
- Role: `FR_DATA_ENGINEER`, warehouse: `WH_INGESTION_XSMALL`

## Quickstart Sources (cloned, immutable)

| Clone | Original |
|-------|----------|
| `quickstarts/dataengineering-ml-snowpark` | `sfguide-getting-started-dataengineering-ml-snowpark-python` |
| `quickstarts/dbt-on-snowflake` | `getting-started-with-dbt-on-snowflake` |

Hardcoded-name mapping for these repos: see
[phase1-repository-scan.md](../../phase1-repository-scan.md).
