-- ============================================================================
-- Snowflake Platform Demo — Environment Reset
-- Run between dry-runs and live presentations to restore a clean state.
-- ============================================================================
-- WARNING: Destroys demo session objects. Foundation objects (roles,
-- warehouses, database, schemas) are preserved so 00_foundation.sql does not
-- need to be re-run.
-- Parameters mirror ../scripts/00_foundation.sql — keep both in sync.
-- Execution: snowsql -f scripts/99_demo_reset.sql
-- ============================================================================

SET db_name           = 'SUPERINTENDENCY_DEMO_DB';
SET schema_core       = 'CORE_BANKING_SCHEMA';
SET schema_analytics  = 'RISK_ANALYTICS_SCHEMA';
SET schema_governance = 'GOVERNANCE_SCHEMA';

USE ROLE FR_DEMO_ADMIN;
USE WAREHOUSE WH_INGESTION_XSMALL;

-- ---------------------------------------------------------------------------
-- Session 1 — Lakehouse & Engineering
-- ---------------------------------------------------------------------------
-- EXECUTE IMMEDIATE 'DROP PIPE IF EXISTS ' || $db_name || '.' || $schema_core || '.<PIPE_NAME>';
-- EXECUTE IMMEDIATE 'DROP STAGE IF EXISTS ' || $db_name || '.' || $schema_core || '.<STAGE_NAME>';
-- EXECUTE IMMEDIATE 'TRUNCATE TABLE ' || $db_name || '.' || $schema_core || '.CREDIT_CARD_TRANSACTIONS';
-- EXECUTE IMMEDIATE 'TRUNCATE TABLE ' || $db_name || '.' || $schema_core || '.CLIENT_PROFILE_DIM';

-- ---------------------------------------------------------------------------
-- Session 2 — AI & Analytics
-- ---------------------------------------------------------------------------
-- EXECUTE IMMEDIATE 'DROP STREAMLIT IF EXISTS ' || $db_name || '.' || $schema_analytics || '.<STREAMLIT_NAME>';
-- EXECUTE IMMEDIATE 'DROP STAGE IF EXISTS ' || $db_name || '.' || $schema_core || '.REGULATORY_DOCS';
-- EXECUTE IMMEDIATE 'DROP TABLE IF EXISTS ' || $db_name || '.' || $schema_analytics || '.DOC_CHUNKS_EMBEDDINGS';

-- ---------------------------------------------------------------------------
-- Session 3 — Governance & Security
-- ---------------------------------------------------------------------------
-- EXECUTE IMMEDIATE 'ALTER TABLE ' || $db_name || '.' || $schema_core || '.CLIENT_PROFILE_DIM'
--     || ' MODIFY COLUMN NATIONAL_ID UNSET MASKING POLICY';
-- EXECUTE IMMEDIATE 'ALTER TABLE ' || $db_name || '.' || $schema_core || '.CREDIT_CARD_TRANSACTIONS'
--     || ' MODIFY COLUMN CREDIT_CARD_NUMBER UNSET MASKING POLICY';
-- EXECUTE IMMEDIATE 'DROP MASKING POLICY IF EXISTS ' || $db_name || '.' || $schema_governance || '.MASK_CREDIT_CARD';
-- EXECUTE IMMEDIATE 'DROP MASKING POLICY IF EXISTS ' || $db_name || '.' || $schema_governance || '.MASK_NATIONAL_ID';
-- EXECUTE IMMEDIATE 'DROP ROW ACCESS POLICY IF EXISTS ' || $db_name || '.' || $schema_governance || '.RLS_BUSINESS_UNIT';
-- EXECUTE IMMEDIATE 'DROP TABLE IF EXISTS ' || $db_name || '.' || $schema_governance || '.ROLE_MAPPING';

SELECT 'Demo environment reset complete' AS STATUS;
