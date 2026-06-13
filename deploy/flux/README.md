# FluxCD Stack

This directory contains FluxCD examples for the Hermes SRE Kubernetes stack.

It reconciles two separate Helm releases:

1. `mcp-server-kubernetes` from the readonly Kubernetes MCP chart repository.
2. `hermes` from this repository's `charts/hermes-agent` chart.

The Hermes chart still deploys Hermes only. Kubernetes API access belongs to the MCP release.

## Secrets

Create the shared MCP auth token Secret before reconciling the stack:

```sh
kubectl create namespace hermes-sre --dry-run=client -o yaml | kubectl apply -f -
kubectl -n hermes-sre create secret generic hermes-mcp-auth \
  --from-literal=mcpAuthToken="${MCP_AUTH_TOKEN}"
```

Create runtime gateway credentials separately:

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

Apply the full stack:

```sh
kubectl apply -k deploy/flux
```

Force reconciliation when needed:

```sh
flux reconcile source git mcp-server-kubernetes -n hermes-sre
flux reconcile helmrelease mcp-server-kubernetes -n hermes-sre
flux reconcile source git hermes-sre-profile -n hermes-sre
flux reconcile helmrelease hermes -n hermes-sre
```

## Verify

```sh
flux get sources git -n hermes-sre
flux get helmreleases -n hermes-sre
kubectl -n hermes-sre rollout status deployment/mcp-server-kubernetes
kubectl -n hermes-sre rollout status deployment/hermes-hermes-agent
```

Then port-forward the Hermes dashboard:

```sh
kubectl -n hermes-sre port-forward svc/hermes-hermes-agent 9119:9119
```
