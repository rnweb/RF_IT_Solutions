# Snowflake Platform Demo

Snowflake demonstration for the **Superintendency of Banks**, prepared and deployed
through an OpenCode-driven automation strategy — reducing environment setup time from
weeks to days with a standardized, repeatable deployment.

## Demo Sessions

| Session | Theme | Highlights |
|---------|-------|------------|
| 1 | Lakehouse & Data Engineering | Snowpipe ingestion, external stages, dbt transformation layers |
| 2 | AI & Analytics | Snowpark ML, Cortex RAG over regulatory documents, Streamlit in Snowflake |
| 3 | Governance & Security | Dynamic Data Masking, Row-Level Security, role-based access matrix |

## Approach

1. **Ingestion & Contextualization** — clone the official Snowflake-Labs Quickstarts
   and translate generic objects into the banking persona.
2. **Orchestrated Deployment** — deploy foundation, then each session's assets in order.
3. **Validation & Teardown Engineering** — automated checks plus a reset script for a
   clean environment before every live presentation.

## In This Section

- [Architecture & Automation Strategy](architecture.md) — core premises, prerequisites,
  three-phase workflow, prompting playbook, and security guardrails.

## Project Assets

Working files (SQL scripts, prompts, naming conventions, Quickstart clones) live in
[`Demo/SB_Demo/`](https://github.com/rnweb/Snowflake_demo/tree/main/Demo/SB_Demo) of the
[Snowflake_demo](https://github.com/rnweb/Snowflake_demo) repository — the home of all
Snowflake demos, POCs and tests.
