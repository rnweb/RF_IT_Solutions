# Session 3 — Governance & Security

Assets for the third demonstration session.

## Scope

- Row-Level Security **binding** via `ALTER TABLE ... ADD ROW ACCESS POLICY`
  (the policy object itself is Terraform-managed — `terraform/governance.tf`)
- Seed data for the `ROLE_MAPPING` table (data stays out of Terraform)
- Masking policies (`MASK_NATIONAL_ID`, `MASK_CREDIT_CARD`) are Terraform-managed and
  bound by setting `attach_policies_to_tables = true` in `terraform/terraform.tfvars`
- Access matrix: `ACCOUNTADMIN`/`FR_DEMO_ADMIN` see plaintext,
  `FR_BI_ANALYST` sees masked/filtered data

## Planned Files

| File | Purpose |
|------|---------|
| `01_rls_binding.sql` | `ALTER TABLE ... ADD ROW ACCESS POLICY` (no Terraform resource exists) |
| `02_load_role_mapping.sql` | Seed `GOVERNANCE_SCHEMA.ROLE_MAPPING` rows |
| `03_validation_masking.py` | Asserts plaintext for admin vs. masked/filtered for `FR_BI_ANALYST` |

> Infrastructure (policies, mapping table DDL, grants) is **not** defined here —
> see [`terraform/governance.tf`](../../terraform/governance.tf).

## Prerequisites

- Sessions 1–2 completed (tables with PII columns exist)
- `terraform apply` run with `attach_policies_to_tables = true` (masking bound)
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
