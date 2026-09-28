# ============================================================================
# Snowflake Platform Demo — Security (Roles, Hierarchy, RBAC Grants)
# ============================================================================
# Hierarchy:  FR_DEMO_ADMIN
#               ├── FR_DATA_ENGINEER
#               └── FR_BI_ANALYST
#
# Least privilege: the engineer builds, the analyst reads (masked), the admin
# orchestrates. No demo role receives ACCOUNTADMIN.
# ============================================================================

# ---------------------------------------------------------------------------
# Roles
# ---------------------------------------------------------------------------
resource "snowflake_account_role" "admin" {
  name    = var.role_admin
  comment = "Agent-scoped admin role — hierarchy root of the demo roles."
}

resource "snowflake_account_role" "engineer" {
  name    = var.role_engineer
  comment = "Pipeline creation: dbt, Snowpipe, Snowpark."
}

resource "snowflake_account_role" "analyst" {
  name    = var.role_analyst
  comment = "Read-only persona used to demonstrate masking and row-level security."
}

# ---------------------------------------------------------------------------
# Role hierarchy
# ---------------------------------------------------------------------------
resource "snowflake_grant_account_role" "engineer_to_admin" {
  role_name        = snowflake_account_role.engineer.name
  parent_role_name = snowflake_account_role.admin.name
}

resource "snowflake_grant_account_role" "analyst_to_admin" {
  role_name        = snowflake_account_role.analyst.name
  parent_role_name = snowflake_account_role.admin.name
}

# ---------------------------------------------------------------------------
# FR_DEMO_ADMIN — database, schemas, warehouses, policy authoring
# ---------------------------------------------------------------------------
resource "snowflake_grant_privileges_to_account_role" "admin_db_usage" {
  account_role_name = snowflake_account_role.admin.name
  privileges        = ["USAGE", "MONITOR"]
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.demo.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "admin_all_schemas" {
  account_role_name = snowflake_account_role.admin.name
  privileges        = ["USAGE", "MONITOR", "CREATE SCHEMA"]
  on_schema {
    all_schemas_in_database = snowflake_database.demo.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "admin_wh_ingestion" {
  account_role_name = snowflake_account_role.admin.name
  privileges        = ["USAGE", "MONITOR"]
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.ingestion.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "admin_wh_cortex" {
  account_role_name = snowflake_account_role.admin.name
  privileges        = ["USAGE", "MONITOR"]
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.cortex.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "admin_wh_app" {
  account_role_name = snowflake_account_role.admin.name
  privileges        = ["USAGE", "MONITOR"]
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.app.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "admin_policy_authoring" {
  account_role_name = snowflake_account_role.admin.name
  privileges = [
    "CREATE MASKING POLICY",
    "CREATE ROW ACCESS POLICY",
    "CREATE TAG",
    "APPLY MASKING POLICY",
    "APPLY ROW ACCESS POLICY",
  ]
  on_schema {
    schema_name = snowflake_schema.governance.fully_qualified_name
  }
}

# ---------------------------------------------------------------------------
# FR_DATA_ENGINEER — build in raw / staging / analytics layers
# ---------------------------------------------------------------------------
resource "snowflake_grant_privileges_to_account_role" "engineer_db_usage" {
  account_role_name = snowflake_account_role.engineer.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.demo.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "engineer_core_build" {
  account_role_name = snowflake_account_role.engineer.name
  privileges        = ["USAGE", "CREATE TABLE", "CREATE VIEW", "MODIFY", "ADD SEARCH OPTIMIZATION"]
  on_schema {
    schema_name = snowflake_schema.core.fully_qualified_name
  }
}

resource "snowflake_grant_privileges_to_account_role" "engineer_staging_build" {
  account_role_name = snowflake_account_role.engineer.name
  privileges        = ["USAGE", "CREATE TABLE", "CREATE VIEW", "MODIFY", "ADD SEARCH OPTIMIZATION"]
  on_schema {
    schema_name = snowflake_schema.staging.fully_qualified_name
  }
}

resource "snowflake_grant_privileges_to_account_role" "engineer_analytics_build" {
  account_role_name = snowflake_account_role.engineer.name
  privileges        = ["USAGE", "CREATE TABLE", "CREATE VIEW", "MODIFY", "ADD SEARCH OPTIMIZATION"]
  on_schema {
    schema_name = snowflake_schema.analytics.fully_qualified_name
  }
}

resource "snowflake_grant_privileges_to_account_role" "engineer_governance_read" {
  account_role_name = snowflake_account_role.engineer.name
  privileges        = ["USAGE"]
  on_schema {
    schema_name = snowflake_schema.governance.fully_qualified_name
  }
}

resource "snowflake_grant_privileges_to_account_role" "engineer_wh_ingestion" {
  account_role_name = snowflake_account_role.engineer.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.ingestion.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "engineer_wh_cortex" {
  account_role_name = snowflake_account_role.engineer.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.cortex.name
  }
}

# ---------------------------------------------------------------------------
# FR_BI_ANALYST — read-only (masking/RLS apply at query time)
# ---------------------------------------------------------------------------
resource "snowflake_grant_privileges_to_account_role" "analyst_db_usage" {
  account_role_name = snowflake_account_role.analyst.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.demo.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "analyst_core_read" {
  account_role_name = snowflake_account_role.analyst.name
  privileges        = ["USAGE"]
  on_schema {
    schema_name = snowflake_schema.core.fully_qualified_name
  }
}

resource "snowflake_grant_privileges_to_account_role" "analyst_core_select_all" {
  account_role_name = snowflake_account_role.analyst.name
  privileges        = ["SELECT"]
  on_schema_object {
    all {
      in_schema          = snowflake_schema.core.fully_qualified_name
      object_type_plural = "TABLES"
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "analyst_core_select_future" {
  account_role_name = snowflake_account_role.analyst.name
  privileges        = ["SELECT"]
  on_schema_object {
    future {
      in_schema          = snowflake_schema.core.fully_qualified_name
      object_type_plural = "TABLES"
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "analyst_staging_read" {
  account_role_name = snowflake_account_role.analyst.name
  privileges        = ["USAGE"]
  on_schema {
    schema_name = snowflake_schema.staging.fully_qualified_name
  }
}

resource "snowflake_grant_privileges_to_account_role" "analyst_staging_select_all" {
  account_role_name = snowflake_account_role.analyst.name
  privileges        = ["SELECT"]
  on_schema_object {
    all {
      in_schema          = snowflake_schema.staging.fully_qualified_name
      object_type_plural = "TABLES"
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "analyst_staging_select_future" {
  account_role_name = snowflake_account_role.analyst.name
  privileges        = ["SELECT"]
  on_schema_object {
    future {
      in_schema          = snowflake_schema.staging.fully_qualified_name
      object_type_plural = "TABLES"
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "analyst_analytics_read" {
  account_role_name = snowflake_account_role.analyst.name
  privileges        = ["USAGE"]
  on_schema {
    schema_name = snowflake_schema.analytics.fully_qualified_name
  }
}

resource "snowflake_grant_privileges_to_account_role" "analyst_analytics_select_all" {
  account_role_name = snowflake_account_role.analyst.name
  privileges        = ["SELECT"]
  on_schema_object {
    all {
      in_schema          = snowflake_schema.analytics.fully_qualified_name
      object_type_plural = "TABLES"
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "analyst_analytics_select_future" {
  account_role_name = snowflake_account_role.analyst.name
  privileges        = ["SELECT"]
  on_schema_object {
    future {
      in_schema          = snowflake_schema.analytics.fully_qualified_name
      object_type_plural = "TABLES"
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "analyst_wh_cortex" {
  account_role_name = snowflake_account_role.analyst.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.cortex.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "analyst_wh_app" {
  account_role_name = snowflake_account_role.analyst.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.app.name
  }
}
