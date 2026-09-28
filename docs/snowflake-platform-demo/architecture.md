# Architecture Documentation and Automation Strategy with OpenCode

This document outlines the comprehensive architecture, prerequisites, and execution
strategy for utilizing OpenCode (or a similar autonomous AI coding agent) to automate
the preparation of the Snowflake demonstration for the Superintendency of Banks. By
leveraging an AI agent to parse, consolidate, and deploy Snowflake Quickstarts, the
environment setup time will be reduced from weeks to days, ensuring a highly
standardized and repeatable deployment.

## 1. Core Premises

To effectively utilize an autonomous AI agent for this deployment, the following
foundational assumptions must be established:

- **Deterministic Execution:** The AI agent will act as an orchestrator and executor,
  taking high-level intents (e.g., "Deploy the Cortex Document Chatbot Quickstart") and
  translating them into sequential CLI commands, SQL executions, and Python script
  deployments.
- **Source of Truth:** The official Snowflake Quickstart GitHub repositories
  ([github.com/Snowflake-Labs/sfguide-\*](https://github.com/Snowflake-Labs)) will serve
  as the immutable source of truth for all base code, datasets, and architectural
  patterns.
- **Idempotency:** All scripts generated and executed by the agent must be idempotent.
  The agent must use `CREATE OR REPLACE` or `CREATE IF NOT EXISTS` statements to ensure
  the demo environment can be easily reset or redeployed without state conflicts between
  the three planned sessions.
- **Parameterization:** The agent will not blindly execute downloaded scripts. It must
  intelligently parse the Quickstart SQL/Python files and abstract hardcoded values
  (e.g., database names, roles, warehouses) into standardized variables matching the
  banking context (e.g., renaming `QUICKSTART_DB` to `SUPERINTENDENCY_DEMO_DB`).

## 2. System Needs & Prerequisites

Before initiating the OpenCode agent, the local or cloud workspace environment must be
rigorously prepared with the following access and tooling configurations:

- **Snowflake Environment:**
    - A dedicated Snowflake Account (preferably Enterprise or Business Critical edition
      to support advanced governance and PrivateLink/Tri-Secret Secure features if
      requested).
    - A dedicated service account user with `ACCOUNTADMIN` privileges or a custom
      `SYSADMIN` + `SECURITYADMIN` role setup specifically for the agent's execution
      scope.
- **Agent Workspace Setup (OpenCode Environment):**
    - **Version Control:** Git installed and configured to clone Snowflake repositories.
    - **Execution CLI:** Snowflake CLI (`snowsql`) installed, configured, and
      authenticated via a credentials file (`~/.snowsql/config`) or environment variables
      (`SNOWSQL_ACCOUNT`, `SNOWSQL_USER`, `SNOWSQL_PWD`) so the agent can execute `.sql`
      files non-interactively.
    - **Python Ecosystem:** Python 3.9+ installed with a virtual environment containing
      `snowflake-snowpark-python`, `snowflake-ml-python`, `streamlit`, and
      `dbt-snowflake`.
    - **Infrastructure as Code (IaC):** Terraform CLI installed (if IaC is selected for
      the foundational setup).

## 3. Agentic Automation Strategy

The deployment will be executed in a three-phase workflow, guided by specific prompts
fed to the OpenCode agent.

### Phase 1: Ingestion & Contextualization

The agent's first task is to gather the raw materials and adapt them to the banking
persona.

- **Task:** Command the agent to clone the targeted Quickstart repositories (Data
  Engineering, dbt, Cortex, Data Governance).
- **Translation:** Instruct the agent to run a regex or AST (Abstract Syntax Tree)
  parsing over the cloned repositories to rename generic entities to banking equivalents
  (e.g., translating "Retail Sales" tables to "Credit Card Transactions").
- **Consolidation:** The agent will merge disparate setup scripts into a single,
  cohesive `00_demo_foundation_setup.sql` file that creates the required Warehouses,
  Databases, Schemas, and base Roles.

### Phase 2: Orchestrated Deployment by Session

The agent will execute the deployments segmented by the three defined demonstration
sessions to maintain logical separation.

- **Session 1 Assets (Lakehouse & Engineering):** The agent will execute the Snowpipe
  configuration scripts, pulling public financial datasets from external stages
  (AWS S3/GCS). It will then initialize the dbt project, set up the `profiles.yml`
  automatically, and run `dbt build` to populate the transformation layers.
- **Session 2 Assets (AI & Analytics):** The agent will deploy the Snowpark ML training
  scripts via Python. For the Cortex RAG implementation, the agent will upload the
  simulated bank regulatory PDF to a Snowflake internal stage, create the vector
  embeddings, and deploy the Streamlit application code directly to Snowflake using the
  `snow streamlit deploy` command.
- **Session 3 Assets (Governance & Security):** The agent will execute the Data
  Governance Quickstart scripts, applying `MASKING POLICIES` to the newly created
  banking tables (masking simulated SSNs and Credit Card numbers) and establishing the
  Row-Level Security mapping tables.

### Phase 3: Validation & Teardown Engineering

- **Dry-Run Testing:** The agent will run a suite of automated `SELECT` queries across
  the provisioned assets to verify row counts, ensure masking policies are actively
  blocking PII for unauthorized roles, and test that the Cortex LLM functions are
  responding.
- **Reset Scripts:** The agent will generate a `99_demo_reset.sql` script. This is
  critical for you to run between your dry-runs and the actual client presentation,
  ensuring the environment is perfectly clean for the live demonstration.

## 4. Prompting Playbook for OpenCode

To enforce strict adherence to the architecture, use the following structured prompt
sequence when instructing your OpenCode agent:

**Prompt 1: Workspace Initialization & Cloning**

> "You are an expert Snowflake Data Architect preparing a highly regulated banking
> demonstration. Clone the following Snowflake Quickstart repositories to the local
> workspace: [Insert Repo URLs for Snowpark, Cortex, Governance]. Once cloned, analyze
> the SQL setup files in each repository. Identify all hardcoded Database, Schema, and
> Role names. Do not execute anything yet; output a mapping table showing the original
> names and your proposed banking-specific names (e.g., `DEMO_DB` ->
> `SUPERINTENDENCY_DEMO_DB`)."

**Prompt 2: Code Refactoring & Parameterization**

> "Apply the approved banking-specific naming conventions across all SQL and Python files
> in the cloned repositories. Ensure all scripts are idempotent by utilizing
> `CREATE OR REPLACE`. Consolidate the foundational infrastructure creation (Warehouses,
> Databases, Schemas, base Roles) into a single file named `00_foundation.sql`. Confirm
> when this file is ready."

**Prompt 3: Automated Execution & Validation**

> "Using the configured `snowsql` CLI and the active Python environment, execute
> `00_foundation.sql`. Proceed to execute the Data Governance scripts to apply Dynamic
> Data Masking to the 'CREDIT_CARD' and 'NATIONAL_ID' columns. Finally, write and execute
> a Python script that asserts the masking policy is working by querying the table using
> the `ACCOUNTADMIN` role (should see plaintext) and a simulated `BI_ANALYST` role
> (should see masked data). Report the validation results."

## 5. Security & Guardrails

When utilizing autonomous agents for cloud infrastructure deployment, strict boundaries
must be maintained:

- **Credential Isolation:** Never hardcode Snowflake credentials into the prompts or the
  scripts the agent generates. Ensure OpenCode strictly uses local environment variables
  or a secure key vault.
- **Scope Restriction:** If possible, limit the Snowflake role provided to the agent.
  Instead of `ACCOUNTADMIN`, grant a custom role with `CREATE DATABASE`,
  `CREATE WAREHOUSE`, and `MANAGE GRANTS` to prevent the agent from accidentally
  modifying any existing non-demo assets in your Snowflake tenant.
- **Human-in-the-Loop:** Do not allow the agent to execute the final Streamlit
  deployments or Cortex LLM setup without manual review of the generated code, as
  AI-generated Streamlit UI components may require aesthetic adjustments to match the
  Superintendency's expectations.
