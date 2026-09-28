-- ============================================================================
-- Snowflake Platform Demo — Environment Reset
-- Run between dry-runs and live presentations to restore a clean state.
-- ============================================================================
-- WARNING: Destroys demo session objects. Foundation objects (roles,
-- warehouses, databases) are preserved so 00_foundation.sql does not need
-- to be re-run.
-- Execution: snowsql -f scripts/99_demo_reset.sql
-- ============================================================================

USE ROLE BANKING_DEMO_SECURITYADMIN;
USE WAREHOUSE BANKING_DEMO_WH;

-- ---------------------------------------------------------------------------
-- Session 1 — Lakehouse & Engineering
-- ---------------------------------------------------------------------------
-- DROP PIPE IF EXISTS BANKING_DEMO_DB.RAW.<PIPE_NAME>;
-- DROP STAGE IF EXISTS BANKING_DEMO_DB.RAW.<STAGE_NAME>;
-- DELETE FROM BANKING_DEMO_DB.RAW.CREDIT_CARD_TRANSACTIONS WHERE 1=1;

-- ---------------------------------------------------------------------------
-- Session 2 — AI & Analytics
-- ---------------------------------------------------------------------------
-- DROP STREAMLIT IF EXISTS BANKING_DEMO_DB.ANALYTICS.<STREAMLIT_NAME>;
-- DROP STAGE IF EXISTS BANKING_DEMO_DB.ML.REGULATORY_DOCS;
-- DROP TABLE IF EXISTS BANKING_DEMO_DB.ML.DOC_CHUNKS_EMBEDDINGS;
-- CALL BANKING_DEMO_DB.ML.<MODEL_NAME>() -- unregister trained model

-- ---------------------------------------------------------------------------
-- Session 3 — Governance & Security
-- ---------------------------------------------------------------------------
-- DROP ROW ACCESS POLICY IF EXISTS BANKING_DEMO_DB.GOVERNANCE.<RLS_POLICY>;
-- ALTER TABLE BANKING_DEMO_DB.RAW.CREDIT_CARD_TRANSACTIONS
--     MODIFY COLUMN CREDIT_CARD_NUMBER UNSET MASKING POLICY;
-- ALTER TABLE BANKING_DEMO_DB.RAW.CUSTOMERS
--     MODIFY COLUMN NATIONAL_ID UNSET MASKING POLICY;
-- DROP MASKING POLICY IF EXISTS BANKING_DEMO_DB.GOVERNANCE.MASK_CREDIT_CARD;
-- DROP MASKING POLICY IF EXISTS BANKING_DEMO_DB.GOVERNANCE.MASK_NATIONAL_ID;
-- DROP TABLE IF EXISTS BANKING_DEMO_DB.GOVERNANCE.ROLE_MAPPING;

SELECT 'Demo environment reset complete' AS STATUS;
