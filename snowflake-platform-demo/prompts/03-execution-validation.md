# Prompt 3 — Automated Execution & Validation

> Using the configured `snowsql` CLI and the active Python environment, execute
> `00_foundation.sql`. Proceed to execute the Data Governance scripts to apply Dynamic
> Data Masking to the 'CREDIT_CARD' and 'NATIONAL_ID' columns. Finally, write and execute
> a Python script that asserts the masking policy is working by querying the table using
> the `ACCOUNTADMIN` role (should see plaintext) and a simulated `BI_ANALYST` role
> (should see masked data). Report the validation results.

## Execution Order

1. `scripts/00_foundation.sql`
2. Session 1 — Lakehouse & Engineering (`scripts/session-1-lakehouse/`)
3. Session 2 — AI & Analytics (`scripts/session-2-ai-analytics/`) — **human review required
   before any Streamlit/Cortex deploy**
4. Session 3 — Governance & Security (`scripts/session-3-governance/`)
5. Validation queries (row counts, masking assertions, Cortex response checks)
6. `scripts/99_demo_reset.sql` when a clean environment is needed

## Expected Output

- Execution log per script with success/failure status.
- Masking validation results: `ACCOUNTADMIN` → plaintext, `BANKING_DEMO_BI_ANALYST` → masked.
- Validation summary table of row counts and asset checks.
