# Session 2 — AI & Analytics

Assets for the second demonstration session.

## Scope

- Snowpark ML training scripts (Python) for a banking use-case model
- Cortex RAG: simulated bank regulatory PDF uploaded to an internal stage in
  `CORE_BANKING_SCHEMA`, chunked/embedded into `RISK_ANALYTICS_SCHEMA`
- Cortex LLM functions for document Q&A (`CORTEX.SUMMARIZE`, `CORTEX.COMPLETE`)
- Streamlit / Native App chatbot deployed to Snowflake

## Planned Files

| File | Purpose |
|------|---------|
| `01_ml_training.py` | Snowpark ML feature engineering + model training |
| `02_cortex_rag_setup.sql` | Stage upload, chunking, embeddings |
| `03_cortex_rag_queries.sql` | Sample LLM queries for the demo script |
| `app/` | Streamlit / Native App source |

## Prerequisites

- Session 1 data loaded (embeddings need transactional/document data)
- Warehouses: `WH_CORTEX_LARGE` (ML/Cortex), `WH_APP_XSMALL` (app UI)
- **Human-in-the-loop:** generated app code and Cortex setup require manual
  review before deployment (see [Security & Guardrails](../../../docs/snowflake-platform-demo/architecture.md)).

## Quickstart Source (cloned, immutable)

| Clone | Original |
|-------|----------|
| `quickstarts/cortex-native-app-chatbot` | `sfguide-build-chatbot-with-snowflake-native-app-snowflake-cortex` |

> Note: the Native App package requires its own database (proposed
> `SUPERINTENDENCY_CHATBOT_APP`, provisional) — see
> [phase1-repository-scan.md](../../phase1-repository-scan.md).
