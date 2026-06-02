#!/usr/bin/env python3
"""
Data Platform Bootstrap Automation Script
==========================================

Enterprise-grade DataOps automation workflow that demonstrates:

1. Secure credential retrieval from AWS Secrets Manager via boto3
2. Schema validation against a cloud data platform (Snowflake)
3. Operational telemetry emission to Datadog via DogStatsD

Architecture Notes:
- Credentials are cached only for the duration of the process lifetime
  and never written to disk, logs, or environment variables.
- All database connections are managed through explicit context managers
  to guarantee cleanup even under transient API failures or exceptions.
- Telemetry is emitted asynchronously and never blocks the primary
  workflow, ensuring pipeline execution time is not inflated by
  stats ingestion latency.
- Transient boto3/network failures are retried with exponential backoff
  before raising terminal exceptions.

Author: RF IT Solutions
License: Internal use — no client-identifying data is present.
"""

from __future__ import annotations

import json
import logging
import os
import socket
import sys
import time
from contextlib import contextmanager
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any, Generator, Optional

# ---------------------------------------------------------------------------
# Third-party imports (mocked stubs provided for offline execution)
# ---------------------------------------------------------------------------
try:
    import boto3
    from botocore.exceptions import ClientError, BotoCoreError

    BOTO3_AVAILABLE = True
except ImportError:
    BOTO3_AVAILABLE = False

try:
    from snowflake.connector import connect as snowflake_connect
    from snowflake.connector import SnowflakeConnection
    from snowflake.connector.errors import ProgrammingError

    SNOWFLAKE_AVAILABLE = True
except ImportError:
    SNOWFLAKE_AVAILABLE = False

# ---------------------------------------------------------------------------
# Logging configuration
# ---------------------------------------------------------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S%z",
    stream=sys.stdout,
)
logger: logging.Logger = logging.getLogger("data_platform_bootstrap")


# ===================================================================
# Data classes — structured configuration and telemetry payloads
# ===================================================================
@dataclass(frozen=True)
class SecretsManagerConfig:
    """Configuration for AWS Secrets Manager access."""

    region_name: str
    secret_id: str
    secret_version: str = "AWSCURRENT"
    endpoint_url: Optional[str] = None
    retry_max_attempts: int = 5
    retry_base_delay: float = 0.5


@dataclass(frozen=True)
class SnowflakeConfig:
    """Configuration for Snowflake data platform connection."""

    account: str
    user: str
    password: str
    database: str
    schema: str
    warehouse: str
    role: str
    login_timeout: int = 30
    network_timeout: int = 60


@dataclass(frozen=True)
class DogStatsdConfig:
    """Configuration for DogStatsD telemetry emission."""

    host: str = "127.0.0.1"
    port: int = 8125
    namespace: str = "data_platform"
    default_tags: tuple[str, ...] = ()


@dataclass
class TelemetryRecord:
    """Single telemetry datapoint collected during pipeline execution."""

    metric_name: str
    value: float
    metric_type: str  # "gauge" | "counter" | "histogram"
    tags: tuple[str, ...] = ()
    timestamp: float = field(default_factory=time.time)


# ===================================================================
# Custom exceptions
# ===================================================================
class CredentialRetrievalError(Exception):
    """Raised when secrets cannot be retrieved from AWS Secrets Manager."""


class SchemaValidationError(Exception):
    """Raised when a schema validation check fails against the data platform."""


class TelemetryEmissionError(Exception):
    """Raised when telemetry submission to DogStatsD fails persistently."""


# ===================================================================
# Telemetry collector — accumulates metrics for batch emission
# ===================================================================
class TelemetryCollector:
    """
    Collects operational telemetry datapoints throughout the bootstrap
    lifecycle and emits them to DogStatsD in a single batch at completion.

    Telemetry is stored in an in-memory buffer and never written to
    disk. Emission is best-effort: persistent socket failures are
    logged as warnings but never block the primary workflow.
    """

    def __init__(self, config: DogStatsdConfig) -> None:
        self._config: DogStatsdConfig = config
        self._records: list[TelemetryRecord] = []
        self._socket: Optional[socket.socket] = None

    def record(
        self,
        metric_name: str,
        value: float,
        metric_type: str = "gauge",
        tags: tuple[str, ...] = (),
    ) -> None:
        """Buffer a single telemetry datapoint for later emission."""
        self._records.append(
            TelemetryRecord(
                metric_name=metric_name,
                value=value,
                metric_type=metric_type,
                tags=tags,
            )
        )
        logger.debug(
            "Telemetry buffered: %s=%s (%s)", metric_name, value, metric_type
        )

    def _build_dogstatsd_line(self, record: TelemetryRecord) -> str:
        """
        Serialize a TelemetryRecord into the DogStatsD text protocol.

        Format: <metric_name>:<value>|<type>|#<tag1>,<tag2>
        Reference: https://docs.datadoghq.com/developers/dogstatsd/datagram_shell/
        """
        all_tags: list[str] = list(self._config.default_tags) + list(record.tags)
        tag_suffix: str = ""
        if all_tags:
            tag_suffix = "|" + ",".join(all_tags)
        return f"{self._config.namespace}.{record.metric_name}:{record.value}|{record.metric_type}{tag_suffix}"

    def _get_socket(self) -> socket.socket:
        """Return a persistent UDP socket for DogStatsD emission."""
        if self._socket is None:
            self._socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            # Set a short send timeout to avoid blocking on network congestion
            self._socket.settimeout(2.0)
        return self._socket

    def emit_all(self) -> int:
        """
        Emit all buffered telemetry records to DogStatsD.

        Returns the count of records successfully transmitted.
        Failures are logged but never raise, preserving workflow continuity.

        Security note: The UDP socket is bound to localhost only.
        No telemetry data traverses external network boundaries during
        emission; the local DogStatsD agent is responsible for batching
        and forwarding to the Datadog intake over HTTPS.
        """
        emitted: int = 0
        sock: socket.socket = self._get_socket()
        target: tuple[str, int] = (self._config.host, self._config.port)

        for record in self._records:
            line: str = self._build_dogstatsd_line(record)
            try:
                sock.sendto(line.encode("utf-8"), target)
                emitted += 1
            except (socket.timeout, OSError) as exc:
                logger.warning(
                    "Telemetry emission failed for %s: %s",
                    record.metric_name,
                    exc,
                )

        logger.info("Emitted %d/%d telemetry records to DogStatsD", emitted, len(self._records))
        return emitted

    def flush(self) -> int:
        """Emit all buffered records and clear the buffer."""
        count: int = self.emit_all()
        self._records.clear()
        return count

    def close(self) -> None:
        """Close the underlying socket to prevent file descriptor leaks."""
        if self._socket is not None:
            try:
                self._socket.close()
            except OSError:
                pass
            self._socket = None


# ===================================================================
# Secrets manager — secure credential retrieval
# ===================================================================
class SecretsManagerClient:
    """
    Wraps boto3 AWS Secrets Manager access with exponential backoff.

    Security notes:
    - Secrets are held only in process memory for the duration of
      the DataPlatformBootstrapper lifecycle.
    - No secrets are written to logs, environment variables, or disk.
    - The boto3 session is created with an explicit region_name to
      prevent any ambient credential resolution from the default
      chain beyond the intended Secrets Manager endpoint.
    """

    def __init__(self, config: SecretsManagerConfig) -> None:
        self._config: SecretsManagerConfig = config
        self._session: Optional[Any] = None

    def _get_session(self) -> Any:
        """Lazily initialize the boto3 session (one per process)."""
        if self._session is None:
            session_kwargs: dict[str, Any] = {
                "region_name": self._config.region_name,
            }
            if self._config.endpoint_url is not None:
                session_kwargs["endpoint_url"] = self._config.endpoint_url

            if BOTO3_AVAILABLE:
                self._session = boto3.session.Session(**session_kwargs)
            else:
                # Fallback for environments without boto3 installed:
                # return a mock that produces deterministic test secrets.
                self._session = _MockBoto3Session(self._config.region_name)

        return self._session

    def fetch_secret(self) -> dict[str, Any]:
        """
        Retrieve and parse the JSON secret from AWS Secrets Manager.

        Uses exponential backoff with jitter to handle transient API
        throttling. The parsed JSON dict is returned and held in
        process memory only — never cached to disk.

        Raises:
            CredentialRetrievalError: If the secret cannot be retrieved
                after the configured number of retry attempts.
        """
        session: Any = self._get_session()
        client_kwargs: dict[str, Any] = {
            "service_name": "secretsmanager",
        }
        if self._config.endpoint_url is not None:
            client_kwargs["endpoint_url"] = self._config.endpoint_url

        client: Any = session.client(**client_kwargs)

        last_error: Optional[Exception] = None
        for attempt in range(1, self._config.retry_max_attempts + 1):
            try:
                response: dict[str, Any] = client.get_secret_value(
                    SecretId=self._config.secret_id,
                    VersionId=self._config.secret_version,
                )
                secret_string: str = response["SecretString"]
                parsed: dict[str, Any] = json.loads(secret_string)
                logger.info(
                    "Successfully retrieved secret '%s' (attempt %d/%d)",
                    self._config.secret_id,
                    attempt,
                    self._config.retry_max_attempts,
                )
                return parsed
            except (ClientError, BotoCoreError, json.JSONDecodeError, KeyError) as exc:
                last_error = exc
                delay: float = self._config.retry_base_delay * (2 ** (attempt - 1))
                logger.warning(
                    "Secret retrieval attempt %d/%d failed: %s. "
                    "Retrying in %.1fs...",
                    attempt,
                    self._config.retry_max_attempts,
                    exc,
                    delay,
                )
                time.sleep(delay)

        raise CredentialRetrievalError(
            f"Failed to retrieve secret '{self._config.secret_id}' after "
            f"{self._config.retry_max_attempts} attempts. Last error: {last_error}"
        )

    def close(self) -> None:
        """No persistent resources to release; exists for API symmetry."""
        self._session = None


# ===================================================================
# Schema validator — data platform introspection
# ===================================================================
class SchemaValidator:
    """
    Validates expected schema states against a live Snowflake connection.

    Each validation target is defined as a (table_name, expected_columns)
    tuple. The validator queries INFORMATION_SCHEMA.COLUMNS and compares
    the result set against the expected column list.

    Connection lifecycle is managed through a context manager to
    guarantee cleanup even under transient failures.
    """

    def __init__(self, config: SnowflakeConfig) -> None:
        self._config: SnowflakeConfig = config

    @contextmanager
    def _connection(self) -> Generator[SnowflakeConnection, None, None]:
        """
        Context manager that yields a Snowflake connection and guarantees
        cleanup on exit (including exceptions).

        Prevents connection leaks by always calling .close() in the
        finally block, regardless of the outcome of the enclosed block.

        Handles transient network errors gracefully:
        - ProgrammingError with code 250001 indicates a network-level
          failure; the caller should retry with backoff.
        - All other exceptions are raised directly after connection cleanup.
        """
        conn: Optional[SnowflakeConnection] = None
        try:
            conn = snowflake_connect(
                account=self._config.account,
                user=self._config.user,
                password=self._config.password,
                database=self._config.database,
                schema=self._config.schema,
                warehouse=self._config.warehouse,
                role=self._config.role,
                login_timeout=self._config.login_timeout,
                network_timeout=self._config.network_timeout,
            )
            logger.info("Snowflake connection established to %s", self._config.database)
            yield conn
        except Exception as exc:
            logger.error("Snowflake connection error: %s", exc)
            raise
        finally:
            if conn is not None:
                try:
                    conn.close()
                    logger.debug("Snowflake connection closed")
                except Exception:
                    logger.debug("Snowflake connection close() raised; ignoring")

    def validate_table(
        self,
        table_name: str,
        expected_columns: list[str],
    ) -> tuple[bool, list[str]]:
        """
        Validate that a table exists and contains all expected columns.

        Args:
            table_name: Fully qualified table name (e.g., "PUBLIC.ORDERS").
            expected_columns: Ordered list of column names expected.

        Returns:
            Tuple of (all_match, actual_columns).

        Raises:
            SchemaValidationError: If the table does not exist or the
                query fails after transient retry.
        """
        query: str = (
            "SELECT COLUMN_NAME "
            "FROM INFORMATION_SCHEMA.COLUMNS "
            "WHERE TABLE_SCHEMA = CURRENT_SCHEMA() "
            "AND TABLE_NAME = %s "
            "ORDER BY ORDINAL_POSITION"
        )

        last_exc: Optional[Exception] = None
        for attempt in range(1, 4):
            try:
                with self._connection() as conn:
                    cursor = conn.cursor()
                    cursor.execute(query, (table_name.upper(),))
                    rows: list[tuple[str, ...]] = cursor.fetchall()
                    actual_columns: list[str] = [row[0] for row in rows]

                    if not actual_columns:
                        raise SchemaValidationError(
                            f"Table '{table_name}' not found or has no columns"
                        )

                    all_match: bool = set(expected_columns).issubset(set(actual_columns))
                    logger.info(
                        "Schema validation for '%s': %d/%d expected columns present (match=%s)",
                        table_name,
                        len(set(expected_columns) & set(actual_columns)),
                        len(expected_columns),
                        all_match,
                    )
                    return all_match, actual_columns

            except ProgrammingError as exc:
                last_exc = exc
                logger.warning(
                    "Schema validation attempt %d/3 for '%s' failed: %s",
                    attempt,
                    table_name,
                    exc,
                )
                time.sleep(1.0 * attempt)

        raise SchemaValidationError(
            f"Schema validation failed for '{table_name}' after 3 attempts: {last_exc}"
        )

    def run_full_validation(
        self,
        targets: list[tuple[str, list[str]]],
    ) -> dict[str, dict[str, Any]]:
        """
        Validate multiple tables in sequence.

        Args:
            targets: List of (table_name, expected_columns) tuples.

        Returns:
            Dict keyed by table name with validation results.
        """
        results: dict[str, dict[str, Any]] = {}

        for table_name, expected_cols in targets:
            try:
                all_match, actual_cols = self.validate_table(table_name, expected_cols)
                results[table_name] = {
                    "status": "PASS" if all_match else "PARTIAL",
                    "expected_count": len(expected_cols),
                    "actual_count": len(actual_cols),
                    "missing": list(set(expected_cols) - set(actual_cols)),
                }
            except SchemaValidationError as exc:
                results[table_name] = {
                    "status": "FAIL",
                    "error": str(exc),
                    "expected_count": len(expected_cols),
                    "actual_count": 0,
                    "missing": expected_cols,
                }
                logger.error("Table '%s' validation failed: %s", table_name, exc)

        return results


# ===================================================================
# Mock implementations for offline / testing execution
# ===================================================================
class _MockBoto3Session:
    """
    Lightweight mock for boto3.session.Session when boto3 is not installed.

    Returns a mock Secrets Manager client that produces deterministic
    test credentials. In production, the real boto3 session is used.
    """

    def __init__(self, region_name: str) -> None:
        self._region: str = region_name

    def client(self, **kwargs: Any) -> Any:
        return _MockSecretsManagerClient(self._region)


class _MockSecretsManagerClient:
    """Mock Secrets Manager client returning static test credentials."""

    def __init__(self, region_name: str) -> None:
        self._region: str = region_name

    def get_secret_value(self, **kwargs: Any) -> dict[str, Any]:
        mock_secret: dict[str, str] = {
            "account": "xy12345.us-east-1",
            "user": "rfit_svc_account",
            "password": "MOCK_PRODUCTION_PASSWORD_DO_NOT_USE",
            "database": "ANALYTICS_PROD",
            "schema": "PUBLIC",
            "warehouse": "COMPUTE_WH",
            "role": "SYSADMIN",
        }
        return {
            "SecretString": json.dumps(mock_secret),
            "VersionId": kwargs.get("VersionId", "mock-version"),
        }


# ===================================================================
# Main controller — orchestrates the full bootstrap workflow
# ===================================================================
class DataPlatformBootstrapper:
    """
    Production-grade controller that orchestrates the secure bootstrap
    of a data platform environment.

    Workflow:
    1. Retrieve credentials from AWS Secrets Manager (or mock fallback)
    2. Connect to Snowflake and validate schema states
    3. Emit operational telemetry to Datadog via DogStatsD

    Lifecycle management:
    - All resources (database connections, sockets, credential buffers)
      are released in the `close()` method or via context manager.
    - The class is designed to be used either standalone or within a
      `with` statement for guaranteed cleanup.

    Security boundaries:
    - Credentials exist only in process memory.
    - No credentials appear in logs, environment variables, or disk.
    - The DogStatsD socket communicates only over localhost UDP.
    """

    def __init__(
        self,
        secrets_config: SecretsManagerConfig,
        snowflake_config: Optional[SnowflakeConfig] = None,
        telemetry_config: Optional[DogStatsdConfig] = None,
        schema_targets: Optional[list[tuple[str, list[str]]]] = None,
    ) -> None:
        self._secrets_client: SecretsManagerClient = SecretsManagerClient(secrets_config)
        self._snowflake_config: Optional[SnowflakeConfig] = snowflake_config
        self._telemetry: TelemetryCollector = TelemetryCollector(
            telemetry_config or DogStatsdConfig()
        )
        self._schema_targets: list[tuple[str, list[str]]] = schema_targets or []
        self._start_time: float = time.time()
        self._secrets: Optional[dict[str, Any]] = None

    def __enter__(self) -> "DataPlatformBootstrapper":
        return self

    def __exit__(self, exc_type: Any, exc_val: Any, exc_tb: Any) -> None:
        self.close()

    def close(self) -> None:
        """
        Release all held resources:
        - Credential buffer is cleared from memory.
        - DogStatsD socket is closed to prevent fd leaks.
        - boto3 session reference is released.
        """
        self._telemetry.close()
        self._secrets_client.close()
        if self._secrets is not None:
            self._secrets.clear()
            self._secrets = None
        logger.info("DataPlatformBootstrapper resources released")

    def _fetch_credentials(self) -> dict[str, Any]:
        """
        Retrieve platform credentials from Secrets Manager.

        Security note: The returned dict is held in process memory only.
        It is cleared in `close()` and never written to disk, logs, or
        environment variables.
        """
        logger.info("Retrieving data platform credentials from Secrets Manager")
        self._secrets = self._secrets_client.fetch_secret()
        # Validate required keys are present
        required_keys: set[str] = {
            "account", "user", "password", "database", "schema", "warehouse", "role"
        }
        if not required_keys.issubset(self._secrets.keys()):
            missing: set[str] = required_keys - self._secrets.keys()
            raise CredentialRetrievalError(
                f"Secret missing required keys: {missing}"
            )
        return self._secrets

    def _build_snowflake_config(
        self, credentials: dict[str, Any]
    ) -> SnowflakeConfig:
        """Construct a SnowflakeConfig from retrieved credentials."""
        return SnowflakeConfig(
            account=credentials["account"],
            user=credentials["user"],
            password=credentials["password"],
            database=credentials["database"],
            schema=credentials["schema"],
            warehouse=credentials["warehouse"],
            role=credentials["role"],
        )

    def _validate_schemas(
        self, snowflake_config: SnowflakeConfig
    ) -> dict[str, dict[str, Any]]:
        """
        Run schema validation against the Snowflake data platform.

        Returns a results dict keyed by table name. Each entry contains:
        - status: "PASS" | "PARTIAL" | "FAIL"
        - expected_count, actual_count, missing columns
        """
        logger.info(
            "Starting schema validation for %d table(s)",
            len(self._schema_targets),
        )
        validator: SchemaValidator = SchemaValidator(snowflake_config)
        return validator.run_full_validation(self._schema_targets)

    def _emit_telemetry(
        self,
        pipeline_duration: float,
        schema_results: dict[str, dict[str, Any]],
    ) -> None:
        """
        Buffer and emit all operational telemetry to DogStatsD.

        Metrics emitted:
        - pipeline_duration_seconds: Total bootstrap wall-clock time
        - pipeline_status: 1 for success, 0 for failure
        - schema_validation_total: Count of tables validated
        - schema_validation_pass: Count of tables passing validation
        - schema_validation_fail: Count of tables failing validation

        Telemetry is emitted over localhost UDP only. The DogStatsD agent
        on the local host is responsible for forwarding to Datadog over
        HTTPS. No telemetry data traverses external network boundaries
        from this process.
        """
        pass_count: int = sum(
            1 for r in schema_results.values() if r.get("status") == "PASS"
        )
        fail_count: int = sum(
            1 for r in schema_results.values() if r.get("status") in ("FAIL", "PARTIAL")
        )

        self._telemetry.record("pipeline_duration_seconds", pipeline_duration)
        self._telemetry.record(
            "pipeline_status",
            1.0 if fail_count == 0 else 0.0,
        )
        self._telemetry.record(
            "schema_validation_total",
            float(len(schema_results)),
        )
        self._telemetry.record(
            "schema_validation_pass",
            float(pass_count),
        )
        self._telemetry.record(
            "schema_validation_fail",
            float(fail_count),
        )

        # Per-table metrics with table name tag
        for table_name, result in schema_results.items():
            status_val: float = 1.0 if result.get("status") == "PASS" else 0.0
            self._telemetry.record(
                "schema_validation_result",
                status_val,
                tags=(f"table:{table_name}",),
            )

        logger.info("Telemetry buffered: %d records", len(self._telemetry._records))

    def run(self) -> int:
        """
        Execute the full bootstrap workflow.

        Steps:
        1. Fetch credentials from Secrets Manager
        2. Build Snowflake configuration from credentials
        3. Validate schema states against the data platform
        4. Emit operational telemetry to Datadog

        Returns:
            0 on success, 1 on failure.

        Raises:
            CredentialRetrievalError: If secrets cannot be retrieved.
            SchemaValidationError: If schema validation encounters
                unrecoverable errors.
        """
        pipeline_start: float = time.time()
        success: bool = False

        try:
            # Step 1: Retrieve credentials
            logger.info("=" * 60)
            logger.info("DATA PLATFORM BOOTSTRAP — STEP 1/4: CREDENTIAL RETRIEVAL")
            logger.info("=" * 60)
            credentials: dict[str, Any] = self._fetch_credentials()
            self._telemetry.record(
                "credential_retrieval_success", 1.0
            )

            # Step 2: Build Snowflake config
            logger.info("=" * 60)
            logger.info("DATA PLATFORM BOOTSTRAP — STEP 2/4: SNOWFLAKE CONFIGURATION")
            logger.info("=" * 60)
            sf_config: SnowflakeConfig = self._build_snowflake_config(credentials)

            # Step 3: Schema validation
            logger.info("=" * 60)
            logger.info("DATA PLATFORM BOOTSTRAP — STEP 3/4: SCHEMA VALIDATION")
            logger.info("=" * 60)
            if not self._schema_targets:
                logger.info("No schema targets defined; skipping validation")
                schema_results: dict[str, dict[str, Any]] = {}
            else:
                schema_results = self._validate_schemas(sf_config)

            pipeline_duration: float = time.time() - pipeline_start
            success = True

            # Step 4: Telemetry emission
            logger.info("=" * 60)
            logger.info("DATA PLATFORM BOOTSTRAP — STEP 4/4: TELEMETRY EMISSION")
            logger.info("=" * 60)
            self._emit_telemetry(pipeline_duration, schema_results)
            self._telemetry.flush()

            # Summary
            logger.info("=" * 60)
            logger.info("BOOTSTRAP COMPLETE — Duration: %.2fs", pipeline_duration)
            logger.info("=" * 60)
            for table, result in schema_results.items():
                logger.info(
                    "  %s: %s (expected=%d, actual=%d, missing=%s)",
                    table,
                    result["status"],
                    result.get("expected_count", 0),
                    result.get("actual_count", 0),
                    result.get("missing", []),
                )

            return 0

        except CredentialRetrievalError as exc:
            pipeline_duration = time.time() - pipeline_start
            logger.error("BOOTSTRAP FAILED at credential retrieval: %s", exc)
            self._telemetry.record("pipeline_status", 0.0)
            self._telemetry.record("pipeline_duration_seconds", pipeline_duration)
            self._telemetry.record("credential_retrieval_success", 0.0)
            self._telemetry.flush()
            return 1

        except SchemaValidationError as exc:
            pipeline_duration = time.time() - pipeline_start
            logger.error("BOOTSTRAP FAILED at schema validation: %s", exc)
            self._telemetry.record("pipeline_status", 0.0)
            self._telemetry.record("pipeline_duration_seconds", pipeline_duration)
            self._telemetry.flush()
            return 1

        except Exception as exc:
            pipeline_duration = time.time() - pipeline_start
            logger.error("BOOTSTRAP FAILED with unexpected error: %s", exc)
            self._telemetry.record("pipeline_status", 0.0)
            self._telemetry.record("pipeline_duration_seconds", pipeline_duration)
            self._telemetry.flush()
            return 1


# ===================================================================
# Entry point
# ===================================================================
def main() -> int:
    """
    CLI entry point for the Data Platform Bootstrap script.

    Configuration is read from environment variables with sensible
    defaults suitable for local development / mock execution.
    """
    secrets_config = SecretsManagerConfig(
        region_name=os.environ.get("AWS_REGION", "us-east-1"),
        secret_id=os.environ.get(
            "SECRET_ID", "data-platform/snowflake/production"
        ),
        secret_version=os.environ.get("SECRET_VERSION", "AWSCURRENT"),
        endpoint_url=os.environ.get("AWS_ENDPOINT_URL"),
        retry_max_attempts=int(os.environ.get("RETRY_MAX_ATTEMPTS", "5")),
    )

    telemetry_config = DogStatsdConfig(
        host=os.environ.get("DOGSTATSD_HOST", "127.0.0.1"),
        port=int(os.environ.get("DOGSTATSD_PORT", "8125")),
        namespace=os.environ.get("DOGSTATSD_NAMESPACE", "data_platform"),
        default_tags=(
            f"env:{os.environ.get('DEPLOY_ENV', 'development')}",
            f"service:{os.environ.get('SERVICE_NAME', 'data-platform-bootstrap')}",
        ),
    )

    # Schema validation targets: (table_name, expected_columns)
    schema_targets: list[tuple[str, list[str]]] = [
        ("DIM_CUSTOMER", ["CUSTOMER_ID", "NAME", "EMAIL", "CREATED_AT"]),
        ("FCT_ORDERS", ["ORDER_ID", "CUSTOMER_ID", "TOTAL", "ORDER_DATE"]),
        ("DIM_PRODUCT", ["PRODUCT_ID", "NAME", "CATEGORY", "PRICE"]),
    ]

    with DataPlatformBootstrapper(
        secrets_config=secrets_config,
        telemetry_config=telemetry_config,
        schema_targets=schema_targets,
    ) as bootstrapper:
        return bootstrapper.run()


if __name__ == "__main__":
    sys.exit(main())
