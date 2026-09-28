# Session 2 — AI & Analytics

Assets for the second demonstration session.

## Scope

- Snowpark ML training scripts (Python) for a banking use-case model
- Cortex RAG: simulated bank regulatory PDF uploaded to an internal stage,
  chunked and embedded with `SNOWFLAKE.CORTEX.EMBED_TEXT_*`
- Cortex LLM functions for document Q&A (`CORTEX.SUMMARIZE`, `CORTEX.COMPLETE`)
- Streamlit app deployed to Snowflake via `snow streamlit deploy`

## Planned Files

| File | Purpose |
|------|---------|
| `01_ml_training.py` | Snowpark ML feature engineering + model training |
| `02_cortex_rag_setup.sql` | Stage upload, chunking, embeddings |
| `03_cortex_rag_queries.sql` | Sample LLM queries for the demo script |
| `app/` | Streamlit application source |

## Prerequisites

- Session 1 data loaded (embeddings need transactional/document data)
- Role: `BANKING_DEMO_SYSADMIN`, warehouses: `BANKING_DEMO_ML_WH`, `BANKING_DEMO_APP_WH`
- **Human-in-the-loop:** generated Streamlit code and Cortex setup require manual
  review before deployment (see [Security & Guardrails](../../../docs/snowflake-platform-demo/architecture.md)).
