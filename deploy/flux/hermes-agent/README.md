# FluxCD Install

This directory contains a FluxCD example for installing the existing Hermes Agent Helm chart.

The readonly Kubernetes MCP server is a separate FluxCD HelmRelease under `deploy/flux/kubernetes-readonly-mcp`. Install both with `kubectl apply -k deploy/flux`, or install and verify MCP first before reconciling this directory alone.

## Prerequisites

- Flux is bootstrapped in the target cluster with source, kustomize, and helm controllers.
- The readonly Kubernetes MCP server is installed in the `hermes-sre` namespace, preferably from `deploy/flux/kubernetes-readonly-mcp`.
- The MCP service is reachable at:

```text
http://mcp-server-kubernetes.hermes-sre.svc.cluster.local:3001/mcp
```

## Secrets

Create the MCP auth token Secret before reconciling the HelmRelease:

```sh
kubectl create namespace hermes-sre --dry-run=client -o yaml | kubectl apply -f -
kubectl -n hermes-sre create secret generic hermes-mcp-auth \
  --from-literal=mcpAuthToken="${MCP_AUTH_TOKEN}"
```

Inject Slack or other gateway runtime credentials with a separate Secret:

```sh
kubectl -n hermes-sre create secret generic hermes-runtime-env \
  --from-literal=SLACK_BOT_TOKEN="xoxb-..." \
  --from-literal=SLACK_APP_TOKEN="xapp-..." \
  --from-literal=SLACK_ALLOWED_USERS="U01ABC2DEF3,U04XYZ9ABC" \
  --from-literal=SLACK_ALLOWED_CHANNELS="C0123456789,C0987654321" \
  --from-literal=SLACK_HOME_CHANNEL="C0123456789"
```

Do not commit real secret manifests. Use SOPS, External Secrets, Sealed Secrets, or your cluster's existing secret workflow if secrets must be GitOps-managed.

## Reconcile

Apply the full Flux stack:

```sh
kubectl apply -k deploy/flux
```

Or apply this Hermes-only example when MCP and the `hermes-sre` namespace are already managed separately:

```sh
kubectl apply -k deploy/flux/hermes-agent
```

Or copy this directory into the path reconciled by your Flux root `Kustomization`.

Force reconciliation when needed:

```sh
flux reconcile helmrelease mcp-server-kubernetes -n hermes-sre
flux reconcile source git hermes-sre-profile -n hermes-sre
flux reconcile helmrelease hermes -n hermes-sre
```

## Verify

Check Flux state:

```sh
flux get sources git -n hermes-sre
flux get helmreleases -n hermes-sre
```

Check the Kubernetes rollout:

```sh
kubectl -n hermes-sre rollout status deployment/hermes-hermes-agent
```

Access the dashboard:

```sh
kubectl -n hermes-sre port-forward svc/hermes-hermes-agent 9119:9119
```

Open:

```text
http://127.0.0.1:9119
```

## Boundary

This Flux setup installs Hermes only. It does not install the readonly Kubernetes MCP server and does not grant Kubernetes API permissions to the Hermes pod. Kubernetes API access belongs to the separately installed readonly MCP server.
