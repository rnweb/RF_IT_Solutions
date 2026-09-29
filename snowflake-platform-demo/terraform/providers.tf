# ============================================================================
# Snowflake Platform Demo — Provider Configuration
# ============================================================================
#
# Provider source note: this is the official Snowflake provider, the continuation
# of the former Snowflake-Labs/snowflake repository (transferred to the
# snowflakedb organization; GitHub redirects Snowflake-Labs/snowflake to
# snowflakedb/snowflake).
#
# Authentication is handled exclusively via standard environment variables:
#   SNOWFLAKE_ORGANIZATION_NAME / SNOWFLAKE_ACCOUNT_NAME (or SNOWFLAKE_ACCOUNT)
#   SNOWFLAKE_USER
#   SNOWFLAKE_PASSWORD        — or —
#   SNOWFLAKE_AUTHENTICATOR + SNOWFLAKE_PRIVATE_KEY_PATH  (key-pair / externalbrowser)
#   SNOWFLAKE_ROLE            (execution role of the provider session)
#
# Recommended for this configuration: a scoped bootstrap role with
# CREATE DATABASE, CREATE WAREHOUSE, CREATE ROLE, MANAGE GRANTS
# (per the security guardrails — avoid ACCOUNTADMIN in daily operation).
#
# NEVER commit credentials. Use local environment variables or a secret manager.
# ============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "~> 1.0"
    }
  }
}

provider "snowflake" {
  # Preview resources used by governance.tf and main.tf (cannot be set via
  # environment variables):
  preview_features_enabled = [
    "snowflake_table_resource",
    "snowflake_table_column_masking_policy_application_resource",
    "snowflake_stage_resource",
  ]
}
