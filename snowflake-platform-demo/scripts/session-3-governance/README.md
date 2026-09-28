# Session 3 — Governance & Security

Assets for the third demonstration session.

## Scope

- Dynamic Data Masking on `CREDIT_CARD_NUMBER` and `NATIONAL_ID` columns
- Row-Level Security via a role-mapping table and row access policy
- Grants demonstrating masked (`BANKING_DEMO_BI_ANALYST`) vs. full (`ACCOUNTADMIN`)
  visibility

## Planned Files

| File | Purpose |
|------|---------|
| `01_masking_policies.sql` | `MASK_CREDIT_CARD`, `MASK_NATIONAL_ID` policies + column attachment |
| `02_row_level_security.sql` | Role-mapping table + row access policy |
| `03_grants_and_access.sql` | Role grants for the demo access matrix |
| `04_validation_masking.py` | Asserts plaintext for admin vs. masked for analyst |

## Prerequisites

- Sessions 1–2 completed (tables with PII columns exist)
- Role: `BANKING_DEMO_SECURITYADMIN`

## Demo Talking Points

1. Same table, two roles → two different result sets, zero application changes.
2. Masking policies survive BI tool queries (policy follows the column).
3. RLS filters rows by business unit/region for the analyst persona.
