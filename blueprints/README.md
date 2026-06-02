# Architecture-as-Code Blueprints

> **Production-ready infrastructure patterns, fully anonymized, battle-tested, and cleared for enterprise consumption.**

---

## Overview

Welcome to the RF IT Solutions engineering blueprint catalog. This directory hosts **production-grade, battle-tested, and fully anonymized architectural patterns** — reusable infrastructure-as-code templates, Kubernetes manifests, semantic layer configurations, and automation scripts.

Every blueprint reflects our core engineering principles:

- **Zero-trust security boundaries** — Least-privilege IAM, secrets rotation, and network segmentation enforced by default.
- **Declarative GitOps continuous delivery** — All infrastructure defined in version control; no imperative mutations.
- **Unified "glass-box" observability** — Every blueprint includes built-in telemetry hooks and SLO instrumentation.
- **Client-identifying data removed** — No proprietary configuration profiles, credentials, or backend references remain in any published blueprint.

> *These are not toy examples. Every asset in this directory has been validated against production workloads in regulated, high-concurrency enterprise environments.*

---

## Blueprint Directory Matrix

| Blueprint | Technical Stack | Operational Focus |
|-----------|----------------|-------------------|
| [`blueprints/gitops-eks-telemetry/`](gitops-eks-telemetry/) | Terraform, AWS EKS, Argo CD, Datadog | Zero-Trust Kubernetes cluster setup with IRSA automation, External Secrets mapping, and in-cluster observability proxy parameters |
| [`blueprints/semantic-layer-atscale/`](semantic-layer-atscale/) | AtScale XML/JSON Dialects, SQL | Reference dimensional virtualization cube designs, custom metric calculations, and aggregated routing optimizations |
| [`blueprints/data-ops-automation/`](data-ops-automation/) | Python, dbt, GitHub Actions | Secure credential rotation automation, custom APM tracing injection scripts, and self-healing deployment workflows |

### Blueprint Detail

#### `gitops-eks-telemetry/`

A complete EKS cluster provisioning module with all security, deployment, and observability layers pre-configured.

**Includes:**

- `terraform/` — Modular Terraform root with VPC, EKS, Karpenter node groups, IRSA roles, and KMS encryption key configuration.
- `argocd/` — Argo CD ApplicationSets with dynamic environment overlays and progressive delivery (Argo Rollouts) canary policies.
- `secrets/` — External Secrets Operator `ExternalSecret` manifests mapped to AWS Secrets Manager ARNs, plus Reloader controller definitions.
- `observability/` — Datadog Agent DaemonSet, in-cluster Datadog Proxy Service, Kubernetes NetworkPolicy restricting egress to the proxy only.
- `security/` — Pod Security Standards (Restricted), NetworkPolicy baselines, OPA/Gatekeeper constraint templates for IRSA enforcement.

#### `semantic-layer-atscale/`

A reference dimensional modeling package for deploying AtScale semantic layers with optimized aggregate routing.

**Includes:**

- `project/` — AtScale project XML/JSON definitions with conformed dimensions, hierarchy specifications, and decoupled measure groups.
- `measures/` — Custom metric SQL templates with cache-level hints, aggregate table declarations, and time-dimension grain alignment.
- `connections/` — Database connection profile templates for InterSystems IRIS, Snowflake, PostgreSQL, and Trino, with per-dialect SQL generation overrides.
- `security/` — Row-level security filter templates and user-access-group mapping definitions.
- `validation/` — SQL-based metric validation scripts that compare AtScale query outputs against source-system reference queries.

#### `data-ops-automation/`

Reusable automation scripts and workflow definitions for secure operations, pipeline integration, and observability injection.

**Includes:**

- `scripts/` — Python utilities for automated credential rotation (AWS Secrets Manager), APM trace-context injection into dbt runs, and Datadog custom metric emission.
- `workflows/` — GitHub Actions reusable workflow definitions for CI/CD integration (dbt run, Terraform plan/apply, K6 performance gate).
- `dbt/` — dbt project template with snapshot, staging, intermediate, and marts folder structure, plus data-quality test suites.
- `self-healing/` — Kubernetes Job definitions with `ttlSecondsAfterFinished` and pod-garbage-collection controllers for automated cluster cleanup.

---

## Usage and Compliance Guardrails

### Enterprise Consumption

All blueprints in this directory are:

- **Open-source** — Licensed for internal use; no proprietary dependencies or vendor lock-in.
- **Decoupled from client environments** — No proprietary backend configurations, data schemas, or access profiles remain in any published asset.
- **Strictly cleared** — Every blueprint has been audited to ensure zero client-identifying configuration profiles, credentials, or network topology details.
- **Validated in production** — Every asset has been tested and executed against real-world workloads in regulated enterprise environments before publication.

### How to Use

1. **Clone the repository.**
2. **Select the blueprint** matching your infrastructure domain.
3. **Review the README** inside the blueprint directory — each blueprint includes:
   - A requirements section (minimum Terraform version, Kubernetes version, AWS account permissions).
   - A variables reference documenting every configurable parameter.
   - An architecture diagram showing the component relationships and data flow.
   - A deployment walkthrough with exact commands and expected outputs.
4. **Customize for your environment** — Override the variables in your own `terraform.tfvars`, Helm values file, or GitHub Actions workflow variables.
5. **Apply with confidence** — Every blueprint includes pre-flight validation scripts that fail fast if required prerequisites are not met.

### Performance Impact

Based on engagements across the RF IT Solutions client portfolio, deploying standardized blueprint patterns has demonstrated:

- **Time-to-production reduced by up to 60%** compared to building infrastructure from scratch.
- **Configuration drift incidents reduced to zero** for GitOps-managed environments.
- **Observability instrumentation time reduced from days to minutes** with pre-configured proxy and agent templates.

---

## Versioning Strategy

Blueprints follow **Semantic Versioning** (`MAJOR.MINOR.PATCH`):

- `MAJOR` — Breaking changes to variable interfaces, resource naming, or structural layout.
- `MINOR` — New features, additional modules, or expanded provider support.
- `PATCH` — Bug fixes, documentation corrections, or non-breaking improvements.

Each blueprint maintains a `CHANGELOG.md` documenting all versioned changes. Current stable versions are pinned in each blueprint's README.

---

*RF IT Solutions — Engineering Resilient Data Foundations and Enterprise-Scale AI Infrastructure.*
