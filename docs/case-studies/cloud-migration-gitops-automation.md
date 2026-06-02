# Cloud Migration & GitOps Automation

> **End-to-end migration of non-deterministic AI backend workloads from legacy container infrastructure to an immutable, zero-trust Kubernetes platform with declarative GitOps delivery and glass-box observability.**

---

## Infrastructure Transformation Overview

### Context

A Major US Quick-Service Restaurant (QSR) Enterprise Chain operated a growing ecosystem of **AI-driven backend APIs** — including LLM-powered ordering assistants, dynamic menu optimization engines, and predictive inventory models — alongside an automated performance-testing suite designed to validate these non-deterministic workloads under peak consumer traffic.

The infrastructure underpinning these workloads ran on a **legacy AWS ECS and SQS configuration** that had been extended, patched, and manually configured over multiple years. The platform could no longer keep pace with the concurrency demands, deployment frequency, or observability requirements of modern AI workloads.

### Objective

Design and execute a **zero-downtime migration** to an immutable, enterprise-grade cloud architecture that would:

- Eliminate all forms of **configuration drift** through declarative, version-controlled infrastructure.
- Replace ad-hoc cluster access patterns with a **zero-trust, pull-based GitOps** delivery model.
- Provide **deterministic observability** into traditionally opaque, non-deterministic AI inference workloads.
- Enforce strict **data-privacy boundaries** — all metrics and traces captured without traversing external network perimeters.

---

## The Source Bottlenecks: Legacy Container Constraints

### Infrastructure Fragmentation

The legacy environment was built atop **AWS ECS (EC2 launch type)** with an SQS-based asynchronous processing layer. Over successive engineering teams, this architecture had accumulated several critical failure modes:

| Bottleneck | Mechanism | Operational Impact |
|------------|-----------|-------------------|
| **VPC Network Boundary Limitations** | Strict routing rules and hard-coded CIDR allocations prevented cross-account subnet communication | Performance-testing traffic between staging and production environments required convoluted bastion host routing, introducing non-deterministic latency |
| **Cross-Account Subnet Routing Failures** | Misconfigured transit gateway attachments and missing route table entries caused silent packet drops | Test suites sporadically failed with connection timeouts, indistinguishable from genuine model regression |
| **Manual Environment Drift** | Engineers directly SSH'd into EC2 container instances to deploy hotfixes and configuration changes | No two environments (dev, staging, production) were identical; "works in staging" became the standard failure mode during production releases |
| **CI Runner Credential Exposure** | Long-lived AWS IAM access keys were stored as plaintext CI/CD secrets, granting direct `ecs:RunTask` and `ecs:UpdateService` permissions | Any compromised CI pipeline token could mutate production infrastructure; credential rotation required manual CI configuration changes |

### The Telemetry Gap

The legacy monitoring stack — CloudWatch Logs + basic ECS metrics — was fundamentally incapable of observing AI workload behavior:

- **No streaming visibility** — LLM endpoints return responses as incrementally generated tokens over Server-Sent Events (SSE). The legacy stack could only measure request/response boundaries, missing the critical intra-response latency profile.
- **No model-level tracing** — When a response was slow, operators could not distinguish between infrastructure congestion (network, CPU) and model-level regression (increased token generation time due to prompt complexity).
- **No user-experience correlation** — Degraded AI interactions at the consumer edge could not be traced back to specific model versions, infrastructure configurations, or deployment events.

---

## Engineering Execution & GitOps Architecture

RF IT Solutions executed a four-workstream engineering program spanning cluster provisioning, GitOps pipeline engineering, secrets management, and observability instrumentation.

### Workstream 1: AWS EKS Infrastructure Blueprinting

A production-grade Kubernetes cluster was provisioned using **modular Terraform** following the principle of immutable, version-controlled infrastructure.

**Cluster architecture:**

```
┌─────────────────────────────────────────────┐
│              AWS Account                     │
│                                              │
│  ┌─────────────────────────────────────┐    │
│  │          VPC (Private Subnets)       │    │
│  │  ┌──────────────────────────────┐   │    │
│  │  │   EKS Control Plane          │   │    │
│  │  │   - API Server (private)     │   │    │
│  │  │   - etcd (encrypted, backed) │   │    │
│  │  └──────────────────────────────┘   │    │
│  │                                      │    │
│  │  ┌──────────────────────────────┐   │    │
│  │  │   Managed Node Groups        │   │    │
│  │  │   - Graviton (arm64)         │   │    │
│  │  │   - Spot + On-Demand mix     │   │    │
│  │  │   - Karpenter auto-scaling   │   │    │
│  │  └──────────────────────────────┘   │    │
│  └─────────────────────────────────────┘    │
│                                              │
│  ┌─────────────────────────────────────┐    │
│  │   IAM Roles for Service Accounts    │    │
│  │   (IRSA)                            │    │
│  │   - Fine-grained per-pod IAM roles  │    │
│  │   - No long-lived credentials       │    │
│  └─────────────────────────────────────┘    │
└─────────────────────────────────────────────┘
```

**Key design decisions:**

- **Private API server endpoint** — The EKS control plane API server was made accessible only from within the VPC CIDR. No public endpoint. Administrators connect via an AWS Client VPN endpoint with SAML-based authentication.
- **IRSA for every workload** — Each microservice and batch job received a dedicated IAM role mapped via Kubernetes ServiceAccount annotations. No cluster-level IAM credentials were distributed. Pods assumed precisely scoped permissions (e.g., `s3:GetObject` on a specific bucket prefix, `sqs:ReceiveMessage` on a specific queue ARN).
- **Karpenter for node auto-scaling** — Replaced the standard Cluster Autoscaler with Karpenter, enabling sub-second node provisioning and heterogeneous instance-type selection (Graviton spot instances for stateless inference workloads, On-Demand for stateful database pods).
- **Arm64 (Graviton) compute** — All node groups were provisioned on AWS Graviton processors, reducing per-core cost while maintaining full Kubernetes compatibility.

### Workstream 2: Declarative GitOps via Argo CD

The cornerstone of the infrastructure transformation was the migration from imperative (script-based) deployments to a **pure pull-based GitOps workflow**.

**Deployment pipeline architecture:**

```
                                    ┌──────────────────┐
                                    │   GitHub          │
                                    │   - Manifests     │
                                    │   - Helm values   │
                                    │   - Kustomize     │
                                    └────────┬─────────┘
                                             │
                                   push/merge│
                                             ▼
┌─────────────────────┐    webhook    ┌──────────────────────┐
│   GitHub Actions    │──────────────►│   Argo CD (in-cluster) │
│   - CI (test, lint) │              │   - Git repo watcher   │
│   - Build & push    │              │   - Diff & sync        │
│   - Manifest update │              │   - Health check       │
└─────────────────────┘              └──────────────────────┘
                                             │
                                   reconciler│
                                             ▼
                                   ┌──────────────────┐
                                   │   EKS Cluster     │
                                   │   - Deployments   │
                                   │   - Services      │
                                   │   - ConfigMaps    │
                                   └──────────────────┘
```

**Critical implementation details:**

**Dynamic Manifest Generation** — Rather than committing raw YAML to the GitOps repository, RF IT Solutions implemented a **Kustomize + Helm combination**: base Helm charts for standard service patterns (stateless HTTP, stateful worker, cronjob) with environment-specific overlays managed via Kustomize. This eliminated copy-paste drift between environment directories while preserving environment-specific configuration.

**Cluster Self-Healing via `ttlSecondsAfterFinished`** — A persistent vulnerability in the legacy architecture was the storage of long-lived `kubectl` credentials within CI runners, allowing any compromised pipeline to mutate the cluster. RF IT Solutions eliminated this attack surface entirely by:

1. Removing all `kubectl` invocations from CI/CD pipelines.
2. Configuring Argo CD in **auto-sync mode** with `prune: true`.
3. Implementing **automated cleanup controllers** using Kubernetes Jobs with `ttlSecondsAfterFinished: 3600` — ensuring that any batch or test-job Pods were automatically garbage-collected after completion, without any human or CI intervention.

The result: CI pipelines trigger Argo CD syncs via API webhooks but possess **no direct cluster access credentials**. Argo CD is the sole mutating agent within the cluster, and its desired state is defined exclusively in Git.

**Progressive Delivery** — Canary deployments were implemented using Argo Rollouts, with automated promotion or rollback based on real-time metrics from the observability stack. A new model-serving deployment that increased p99 latency beyond the defined SLO threshold was automatically scaled back to the previous stable version.

### Workstream 3: Secrets Management Automation

Credential management was transformed from a manual, error-prone process to an **automated, auditable, rotation-aware pipeline** using the External Secrets Operator (ESO).

**Architecture:**

```
AWS Secrets Manager  ◄──── (automated rotation by IAM/ Lambda)
        │
        │ (ESO reconcile loop)
        ▼
External Secrets Operator (in-cluster)
        │
        │ (native Kubernetes Secret creation)
        ▼
Kubernetes Secrets (encrypted at rest via KMS)
        │
        │ (mounted as env vars or volumes)
        ▼
Application Pods
```

- **Secret definitions as code** — `ExternalSecret` Custom Resources were committed to the GitOps repository, referencing the source secret ARN in AWS Secrets Manager. ESO continuously reconciled these definitions, ensuring that any rotation in Secrets Manager was reflected in-cluster within seconds.
- **Rotation without disruption** — Since ESO creates native Kubernetes Secrets, Pods referencing those secrets via environment variables required a restart to pick up rotated values. This was handled via a **Reloader controller** that watched for `ExternalSecret` updates and automatically triggered rolling restarts of dependent Deployments.
- **No secrets in Git** — At no point in the delivery pipeline were raw credential values written to version control. The GitOps repository contained secret references and metadata only.

### Workstream 4: Deterministic Observability Proxy Design

A core requirement was capturing full observability telemetry for AI workloads without exposing internal network topology or routing traffic through external SaaS endpoints.

**In-cluster Datadog Proxy Architecture:**

```
┌─────────────────────────────────────────┐
│  EKS Cluster                             │
│                                           │
│  ┌──────────┐    ┌──────────────────┐    │
│  │ App Pod   │───►│ Datadog Agent    │    │
│  │ (LLM API) │    │ (DaemonSet)      │    │
│  └──────────┘    └────────┬─────────┘    │
│                           │               │
│                           ▼               │
│                   ┌──────────────────┐    │
│                   │ Datadog Proxy    │    │
│                   │ (in-cluster)     │    │
│                   │ - Metrics        │    │
│                   │ - Traces         │    │
│                   │ - Logs           │    │
│                   └────────┬─────────┘    │
│                            │               │
│                            ▼               │
│                   ┌──────────────────┐    │
│                   │ Datadog Intake   │    │
│                   │ (external via    │    │
│                   │  HTTPS egress)   │    │
│                   └──────────────────┘    │
└─────────────────────────────────────────┘
```

**Key design characteristics:**

- **Agent-to-proxy-to-cloud** — All telemetry data (metrics, traces, logs) was locally aggregated by the Datadog Agent (running as a DaemonSet), then routed through an in-cluster Datadog Proxy Service. The proxy performed buffering, compression, and routing — never exposing internal pod IPs or request payloads to the external network.
- **Network egress restricted** — The proxy was the only Pod permitted egress access to the Datadog intake API. All other Pods had no direct outbound internet access, enforced via Kubernetes NetworkPolicies.
- **No payload inspection** — The proxy operated at the transport layer and did not inspect, log, or cache the telemetry payloads traversing it. Business logic, user queries, and model responses remained strictly within the cluster.

### Workstream 5: GenAI Metrics Engineering

Specialized instrumentation was required to capture AI workload behavior that standard APM tools are not designed to measure.

**Custom APM tracing contracts:**

| KPI | Instrumentation Method | Consuming Dashboard |
|-----|----------------------|---------------------|
| **Time-to-First-Token (TTFT)** | Custom DogStatsD timing metric emitted at the application gateway when the first SSE chunk is dispatched | Real-time LLM response latency |
| **SSE Inter-Token Latency** | Distributed span tagged with `sse.chunk_id` and `sse.delta_ms` recorded between consecutive SSE chunks | Streaming quality monitoring |
| **Token Throughput** | Rate counter `llm.tokens_per_second` aggregated over 10-second windows | Capacity planning dashboard |
| **Model Cold-Start Time** | Datadog Event correlated with K6 warm-up script execution time | Deployment health monitoring |
| **User Drop-Off by SSE Segment** | Custom span tag `sse.dropped_at_segment` recorded when a client disconnects mid-stream | UX optimization funnel |
| **Error Budget Burn Rate** | Datadog SLO monitor tracking error budget consumption for p95 TTFT target of `< 500ms` | SRE pager rotation |

**Distributed tracing integration:**

Every inference request was traced across the full path:
```
Mobile App → API Gateway → LLM Router → Model Pod → Token Generation → SSE Stream
```

Each span carried metadata including model version, prompt token count, response token count, and infrastructure locality (availability zone, node). This enabled the SRE team to answer:

- "Is the latency regression caused by the model version or the node it landed on?"
- "Are users in us-east-1 experiencing higher TTFT than us-west-2?"
- "Did the deployment of model v2.3 increase p95 SSE inter-token latency?"

---

## Technical Outcomes & Operational Pillars

### Zero-Trust Delivery

| Metric | Legacy (ECS) | Post-Migration (EKS + GitOps) |
|--------|--------------|-------------------------------|
| **Cluster Access Method** | Long-lived IAM keys in CI | Pull-based GitOps reconciliation; no credentials in CI |
| **Configuration Drift Incidents** | 12–15 per quarter | Zero (enforced by Argo CD auto-reconciliation) |
| **Deployment Frequency** | 1–2 per week | 8–12 per week (4–6× increase) |
| **Rollback Time** | 25–40 minutes (manual) | 2–4 minutes (Argo CD sync from previous Git commit) |
| **Mean Time to Provision Environment** | 3–5 days (ticket-based) | 18 minutes (Terraform + Karpenter) |

### Glass-Box Telemetry

| Capability | Legacy Stack | Post-Migration |
|-----------|--------------|----------------|
| **AI Workload Observability** | None — only request/response count | Full distributed traces across every inference path; SSE stream-level telemetry |
| **Streaming SSE Monitoring** | Impossible | Real-time dashboards tracking TTFT, inter-token latency, and user drop-off by segment |
| **Model Regression Detection** | Manual — required reproducing customer-reported issues | Automated — SLO burn-rate alerts trigger before users are impacted |
| **Telemetry Data Privacy** | N/A — no streaming telemetry existed | Zero external exposure — all metrics routed through in-cluster proxy |
| **Performance Testing Integration** | Manual — test suites triggered outside CI | Automated K6 suites in CI pipeline with pass/fail gates tied to SLO targets |

### Operational Pillars Realized

- **Immutable Infrastructure** — Every change flows through Git. Drift is automatically detected and reconciled within seconds. No direct mutation is possible.
- **Least-Privilege Security** — Every workload receives the minimum IAM permissions it requires. No pod can access another pod's data, secrets, or metrics.
- **Deterministic Observability** — Non-deterministic AI workloads are measured with deterministic KPIs. SRE teams can distinguish infrastructure faults from model regression with confidence.
- **Production Autonomy** — The GitOps model enables the client's platform team to manage multi-cluster deployments without requiring deep Kubernetes expertise for day-to-day operations.

---

*RF IT Solutions — Engineering Resilient Data Foundations and Enterprise-Scale AI Infrastructure.*
