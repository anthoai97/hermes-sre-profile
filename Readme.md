# Hermes SRE Profile

Read-only Hermes Agent profile and deployment chart for SRE/DevOps support.

The profile is designed to answer developer questions about Kubernetes service health, rollouts, pod state, endpoints, and recent events while reducing manual SRE information gathering.

## What It Does

- Answers service status questions from live Kubernetes evidence.
- Uses terminal access only for read-only `kubectl` inspection.
- Refuses edit, delete, modify, restart, scale, patch, apply, rollback, exec, attach, copy, and port-forward actions.
- Does not inspect Kubernetes Secrets or ConfigMaps.
- Keeps memory disabled so new sessions do not reuse stale operational state.

Example questions:

```text
How many services are running in staging?
Is custody-service running in dev?
What happened with payment-api after my deployment?
I deployed service A, but nothing changed. What should I check?
```

## Contents

```text
profiles/sre-agent/        Hermes profile distribution
charts/hermes-agent/       Helm chart for running Hermes in Kubernetes
```

## Profile Install

From this repository:

```sh
hermes profile install ./profiles/sre-agent --alias sre-devops-agent
```

Configure model access in the installed profile `.env`:

```sh
OPENROUTER_API_KEY=
LOCAL_LLM_BASE_URL=http://localhost:8080/v1
LOCAL_LLM_MODEL=
```

Provider order:

- Primary: OpenRouter
- Fallback: OpenAI Codex OAuth
- Fallback: local OpenAI-compatible `llmcpp` endpoint

For Codex OAuth, run:

```sh
hermes model
```

Then choose OpenAI Codex and complete the OAuth flow.

## Kubernetes Scope

The agent expects `kubectl` to be available in its runtime environment and uses only read-only commands such as:

```sh
kubectl get ...
kubectl describe ...
kubectl logs ...
kubectl rollout status ...
kubectl rollout history ...
kubectl events ...
kubectl top ...
```

Do not grant:

- `secrets`
- `configmaps`
- `pods/exec`
- `pods/attach`
- `pods/portforward`
- mutating verbs such as `create`, `update`, `patch`, or `delete`

## Helm Chart

Install:

```sh
helm upgrade --install hermes ./charts/hermes-agent -f values.local.yaml
```

The chart includes read-only RBAC and optional runtime installation of `kubectl` via an init container. Control the kubectl version in chart values:

```yaml
kubectl:
  enabled: true
  version: v1.30.14
  arch: amd64
```

See [charts/hermes-agent/README.md](charts/hermes-agent/README.md) for chart details.

## Security Defaults

- No Kubernetes Secret access.
- No ConfigMap access.
- No pod exec/attach/port-forward access.
- No file, browser, web, MCP, or code execution toolsets in the Hermes profile.
- No persistent memory for cross-session operational facts.

See [profiles/sre-agent/SOUL.md](profiles/sre-agent/SOUL.md) for the full agent behavior policy.
