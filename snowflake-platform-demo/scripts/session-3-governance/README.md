# Session 3 — Governance & Security

Assets for the third demonstration session.

## Scope

- Dynamic Data Masking on `CLIENT_PROFILE_DIM.NATIONAL_ID` and
  `CREDIT_CARD_TRANSACTIONS.CREDIT_CARD_NUMBER`
- Row-Level Security via a role-mapping table in `GOVERNANCE_SCHEMA`
- Access matrix: `ACCOUNTADMIN`/`FR_DEMO_ADMIN` see plaintext,
  `FR_BI_ANALYST` sees masked data

## Planned Files

| File | Purpose |
|------|---------|
| `01_masking_policies.sql` | `MASK_CREDIT_CARD`, `MASK_NATIONAL_ID` policies + column attachment |
| `02_row_level_security.sql` | Role-mapping table + row access policy |
| `03_grants_and_access.sql` | Role grants for the demo access matrix |
| `04_validation_masking.py` | Asserts plaintext for admin vs. masked for analyst |

## Prerequisites

- Sessions 1–2 completed (tables with PII columns exist)
- Role: `FR_DEMO_ADMIN` / `SECURITYADMIN`, warehouses: `WH_CORTEX_LARGE`

## Quickstart Source (cloned, immutable)

| Clone | Original |
|-------|----------|
| `quickstarts/horizon-data-governance` | `sfguide-getting-started-with-horizon-data-governance-in-snowflake` |

Hardcoded-name mapping (`HRZN_*` → banking targets): see
[phase1-repository-scan.md](../../phase1-repository-scan.md).

## Demo Talking Points

1. Same table, two roles → two different result sets, zero application changes.
2. Masking policies survive BI tool queries (policy follows the column).
3. RLS filters rows by business unit for the analyst persona.
