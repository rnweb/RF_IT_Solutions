# Snowflake Platform Demo

Snowflake demonstration project for the **Superintendency of Banks**, delivered through an
OpenCode-driven automation strategy. Full architecture and guardrails are documented in
[Architecture Documentation](../docs/snowflake-platform-demo/architecture.md).

## Demo Sessions

| Session | Theme | Assets |
|---------|-------|--------|
| 1 | Lakehouse & Data Engineering | Snowpipe, external stages, dbt project (`dbt build`) |
| 2 | AI & Analytics | Snowpark ML, Cortex RAG, Streamlit in Snowflake |
| 3 | Governance & Security | Dynamic Data Masking, Row-Level Security, access grants |

## Repository Structure

```
snowflake-platform-demo/
├── README.md                      # This file — overview and workflow
├── naming-conventions.md          # APPROVED original -> banking persona mapping
├── phase1-repository-scan.md      # Scan report: hardcoded names in cloned Quickstarts
├── prompts/                       # Structured prompts fed to the OpenCode agent
│   ├── 01-workspace-init-cloning.md
│   ├── 02-refactoring-parameterization.md
│   └── 03-execution-validation.md
├── quickstarts/                   # Clone target for Snowflake-Labs repos (not committed)
│   └── README.md
└── scripts/
    ├── 00_foundation.sql          # Parameterized warehouses/DB/schemas/roles (idempotent)
    ├── 99_demo_reset.sql          # Environment reset between dry-runs and presentations
    ├── session-1-lakehouse/       # Snowpipe, stages, dbt initialization
    ├── session-2-ai-analytics/    # Snowpark ML, Cortex RAG, app deployment
    └── session-3-governance/      # Masking policies, row-level security
```

## Execution Workflow

1. **Ingestion & Contextualization** — clone the Snowflake-Labs Quickstarts, produce the
   naming mapping table ([naming-conventions.md](naming-conventions.md)), execute nothing.
2. **Orchestrated Deployment** — run `scripts/00_foundation.sql`, then the scripts of each
   session in order (1 → 2 → 3), reviewing generated code before any Streamlit/Cortex deploy.
3. **Validation & Teardown** — run validation queries (row counts, masking assertions,
   Cortex responses) and `scripts/99_demo_reset.sql` to restore a clean environment.

Use the prompts in [prompts/](prompts/) in sequence to drive the agent through this workflow.

## Prerequisites

- Snowflake account (Enterprise/Business Critical) with a dedicated service user
- Snowflake CLI (`snow`) / `snowsql` configured with environment-based credentials
- Python 3.9+ with `snowflake-snowpark-python`, `snowflake-ml-python`, `streamlit`, `dbt-snowflake`
- Git, and optionally Terraform CLI for the foundational IaC layer

!!! warning "Security Guardrails"
    Never hardcode credentials, restrict the agent's Snowflake role to demo-scoped grants,
    and keep a human review step before Streamlit/Cortex deployments.
