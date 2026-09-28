# Session 1 — Lakehouse & Data Engineering

Assets for the first demonstration session.

## Scope

- External stage + Snowpipe configuration pulling public financial datasets (AWS S3/GCS)
- Raw landing zone in `BANKING_DEMO_DB.RAW` (`CREDIT_CARD_TRANSACTIONS`, `CUSTOMERS`)
- dbt project initialization with automated `profiles.yml`
- `dbt build` to populate staging/analytics transformation layers

## Planned Files

| File | Purpose |
|------|---------|
| `01_stage_setup.sql` | External stage + file format definitions |
| `02_snowpipe_setup.sql` | Snowpipe pipes with auto-ingest |
| `03_sample_data_load.sql` | Initial backfill of raw tables |
| `dbt/` | dbt project (models for staging → analytics) |

## Prerequisites

- `scripts/00_foundation.sql` executed successfully
- Role: `BANKING_DEMO_ENGINEER`, warehouse: `BANKING_DEMO_TRANSFORM_WH`

## Source Quickstarts

_Soon to be cloned under `snowflake-platform-demo/quickstarts/` (see
[prompt 1](../prompts/01-workspace-init-cloning.md))._
