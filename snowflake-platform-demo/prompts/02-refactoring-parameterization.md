# Prompt 2 — Code Refactoring & Parameterization

> Apply the approved banking-specific naming conventions across all SQL and Python files
> in the cloned repositories. Ensure all scripts are idempotent by utilizing
> `CREATE OR REPLACE`. Consolidate the foundational infrastructure creation (Warehouses,
> Databases, Schemas, base Roles) into a single file named `00_foundation.sql`. Confirm
> when this file is ready.

## Preconditions

- `naming-conventions.md` must be approved before this prompt is issued.
- Prompts are executed in order: [01](01-workspace-init-cloning.md) → [02](02-refactoring-parameterization.md) → [03](03-execution-validation.md).

## Rules

- Never execute scripts during this phase — refactoring only.
- Use `CREATE OR REPLACE` / `CREATE ... IF NOT EXISTS` everywhere for idempotency.
- Abstract hardcoded values into variables at the top of each script.
- Foundation output path: `snowflake-platform-demo/scripts/00_foundation.sql`.

## Expected Output

1. Refactored copies of the Quickstart scripts (keep originals untouched in `quickstarts/`).
2. `scripts/00_foundation.sql` ready with roles, warehouses, databases, schemas.
3. Confirmation message listing every changed identifier.
