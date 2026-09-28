-- ============================================================================
-- Snowflake Platform Demo — Foundation Setup (Parameterized)
-- Session 0: Roles, Warehouses, Database, Schemas, Grants
-- ============================================================================
-- Parameterization : every object name comes from the PARAMETERS block below.
--                    Change names there, nowhere else.
-- Idempotency      : CREATE ... IF NOT EXISTS + guarded EXECUTE IMMEDIATE
--                    => safe to re-run at any time.
-- Naming source    : ../naming-conventions.md (approved mapping)
-- Execution        : snowsql -f scripts/00_foundation.sql
--                    (or: snow sql -f scripts/00_foundation.sql)
-- NOTE             : schema/grant statements are built dynamically from the
--                    parameters; validate them in the Phase 3 dry-run.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- PARAMETERS — approved banking context (single source of truth)
-- ---------------------------------------------------------------------------
SET db_name           = 'SUPERINTENDENCY_DEMO_DB';
SET schema_core       = 'CORE_BANKING_SCHEMA';    -- raw ingestion layer
SET schema_analytics  = 'RISK_ANALYTICS_SCHEMA';  -- BI / RLS / Cortex layer
SET wh_ingestion      = 'WH_INGESTION_XSMALL';    -- Snowpipe + dbt
SET wh_cortex         = 'WH_CORTEX_LARGE';        -- ML + Cortex LLM
SET role_engineer     = 'FR_DATA_ENGINEER';
SET role_analyst      = 'FR_BI_ANALYST';

-- PROVISIONAL — pending approval (see ../naming-conventions.md)
SET schema_staging    = 'STAGING_SCHEMA';         -- dbt intermediate layer
SET schema_governance = 'GOVERNANCE_SCHEMA';      -- policies + mapping tables
SET role_admin        = 'FR_DEMO_ADMIN';          -- agent-scoped admin role
SET wh_app            = 'WH_APP_XSMALL';          -- Streamlit in Snowflake

-- ---------------------------------------------------------------------------
-- Roles (SECURITYADMIN creates roles and owns grants)
-- ---------------------------------------------------------------------------
USE ROLE SECURITYADMIN;

CREATE ROLE IF NOT EXISTS IDENTIFIER($role_admin);
CREATE ROLE IF NOT EXISTS IDENTIFIER($role_engineer);
CREATE ROLE IF NOT EXISTS IDENTIFIER($role_analyst);

EXECUTE IMMEDIATE 'GRANT ROLE ' || $role_engineer || ' TO ROLE ' || $role_admin;
EXECUTE IMMEDIATE 'GRANT ROLE ' || $role_analyst  || ' TO ROLE ' || $role_admin;

-- ---------------------------------------------------------------------------
-- Warehouses (SYSADMIN owns compute)
-- ---------------------------------------------------------------------------
USE ROLE SYSADMIN;

CREATE WAREHOUSE IF NOT EXISTS IDENTIFIER($wh_ingestion)
    WITH WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;

CREATE WAREHOUSE IF NOT EXISTS IDENTIFIER($wh_cortex)
    WITH WAREHOUSE_SIZE = 'LARGE'
    AUTO_SUSPEND = 120
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;

CREATE WAREHOUSE IF NOT EXISTS IDENTIFIER($wh_app)
    WITH WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;

-- ---------------------------------------------------------------------------
-- Database & Schemas
-- ---------------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS IDENTIFIER($db_name);

EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS ' || $db_name || '.' || $schema_core;
EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS ' || $db_name || '.' || $schema_analytics;
EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS ' || $db_name || '.' || $schema_staging;
EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS ' || $db_name || '.' || $schema_governance;

-- ---------------------------------------------------------------------------
-- Grants
-- ---------------------------------------------------------------------------
USE ROLE SECURITYADMIN;

-- Database & schema usage
EXECUTE IMMEDIATE 'GRANT USAGE ON DATABASE ' || $db_name || ' TO ROLE ' || $role_admin;
EXECUTE IMMEDIATE 'GRANT USAGE ON DATABASE ' || $db_name || ' TO ROLE ' || $role_engineer;
EXECUTE IMMEDIATE 'GRANT USAGE ON DATABASE ' || $db_name || ' TO ROLE ' || $role_analyst;

EXECUTE IMMEDIATE 'GRANT USAGE ON SCHEMA ' || $db_name || '.' || $schema_core
    || ' TO ROLE ' || $role_engineer;
EXECUTE IMMEDIATE 'GRANT USAGE ON SCHEMA ' || $db_name || '.' || $schema_core
    || ' TO ROLE ' || $role_analyst;
EXECUTE IMMEDIATE 'GRANT USAGE ON SCHEMA ' || $db_name || '.' || $schema_staging
    || ' TO ROLE ' || $role_engineer;
EXECUTE IMMEDIATE 'GRANT USAGE ON SCHEMA ' || $db_name || '.' || $schema_staging
    || ' TO ROLE ' || $role_analyst;
EXECUTE IMMEDIATE 'GRANT USAGE ON SCHEMA ' || $db_name || '.' || $schema_analytics
    || ' TO ROLE ' || $role_engineer;
EXECUTE IMMEDIATE 'GRANT USAGE ON SCHEMA ' || $db_name || '.' || $schema_analytics
    || ' TO ROLE ' || $role_analyst;
EXECUTE IMMEDIATE 'GRANT USAGE ON SCHEMA ' || $db_name || '.' || $schema_governance
    || ' TO ROLE ' || $role_engineer;
EXECUTE IMMEDIATE 'GRANT USAGE ON SCHEMA ' || $db_name || '.' || $schema_governance
    || ' TO ROLE ' || $role_admin;

-- Warehouse usage
EXECUTE IMMEDIATE 'GRANT USAGE ON WAREHOUSE ' || $wh_ingestion || ' TO ROLE ' || $role_admin;
EXECUTE IMMEDIATE 'GRANT USAGE ON WAREHOUSE ' || $wh_ingestion || ' TO ROLE ' || $role_engineer;
EXECUTE IMMEDIATE 'GRANT USAGE ON WAREHOUSE ' || $wh_cortex    || ' TO ROLE ' || $role_admin;
EXECUTE IMMEDIATE 'GRANT USAGE ON WAREHOUSE ' || $wh_cortex    || ' TO ROLE ' || $role_engineer;
EXECUTE IMMEDIATE 'GRANT USAGE ON WAREHOUSE ' || $wh_cortex    || ' TO ROLE ' || $role_analyst;
EXECUTE IMMEDIATE 'GRANT USAGE ON WAREHOUSE ' || $wh_app       || ' TO ROLE ' || $role_admin;
EXECUTE IMMEDIATE 'GRANT USAGE ON WAREHOUSE ' || $wh_app       || ' TO ROLE ' || $role_analyst;

-- Engineer: create objects in the ingestion / staging / analytics layers
EXECUTE IMMEDIATE 'GRANT CREATE TABLE ON SCHEMA ' || $db_name || '.' || $schema_core
    || ' TO ROLE ' || $role_engineer;
EXECUTE IMMEDIATE 'GRANT CREATE TABLE ON SCHEMA ' || $db_name || '.' || $schema_staging
    || ' TO ROLE ' || $role_engineer;
EXECUTE IMMEDIATE 'GRANT CREATE TABLE ON SCHEMA ' || $db_name || '.' || $schema_analytics
    || ' TO ROLE ' || $role_engineer;
EXECUTE IMMEDIATE 'GRANT CREATE TABLE ON SCHEMA ' || $db_name || '.' || $schema_governance
    || ' TO ROLE ' || $role_engineer;
EXECUTE IMMEDIATE 'GRANT CREATE SCHEMA ON DATABASE ' || $db_name
    || ' TO ROLE ' || $role_admin;

-- Analyst: read-only on current and future tables (masking applies at read time)
EXECUTE IMMEDIATE 'GRANT SELECT ON ALL TABLES IN SCHEMA ' || $db_name || '.' || $schema_core
    || ' TO ROLE ' || $role_analyst;
EXECUTE IMMEDIATE 'GRANT SELECT ON FUTURE TABLES IN SCHEMA ' || $db_name || '.' || $schema_core
    || ' TO ROLE ' || $role_analyst;
EXECUTE IMMEDIATE 'GRANT SELECT ON ALL TABLES IN SCHEMA ' || $db_name || '.' || $schema_staging
    || ' TO ROLE ' || $role_analyst;
EXECUTE IMMEDIATE 'GRANT SELECT ON FUTURE TABLES IN SCHEMA ' || $db_name || '.' || $schema_staging
    || ' TO ROLE ' || $role_analyst;
EXECUTE IMMEDIATE 'GRANT SELECT ON ALL TABLES IN SCHEMA ' || $db_name || '.' || $schema_analytics
    || ' TO ROLE ' || $role_analyst;
EXECUTE IMMEDIATE 'GRANT SELECT ON FUTURE TABLES IN SCHEMA ' || $db_name || '.' || $schema_analytics
    || ' TO ROLE ' || $role_analyst;

SELECT 'Foundation setup complete' AS STATUS;
