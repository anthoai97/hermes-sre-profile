# FluxCD Readonly Kubernetes MCP

This directory installs the readonly Kubernetes MCP server with FluxCD.

The Helm chart is sourced from:

```text
https://github.com/anthoai97/mcp-server-kubernetes.git
```

The Flux `HelmRelease` keeps the same deployment posture as `mcp/kubernetes-readonly/values.yaml`:

- runtime image pinned to `flux159/mcp-server-kubernetes:v3.8.0`
- HTTP transport on port `3001`
- service account kubeconfig provider
- readonly and non-destructive MCP tool filters
- readonly Kubernetes RBAC without Secrets or ConfigMaps
- DNS rebinding allowance for `mcp-server-kubernetes.hermes-sre.svc.cluster.local:3001`
- `MCP_AUTH_TOKEN` read from the `hermes-mcp-auth` Secret

Create the shared token before reconciliation:

```sh
kubectl create namespace hermes-sre --dry-run=client -o yaml | kubectl apply -f -
kubectl -n hermes-sre create secret generic hermes-mcp-auth \
  --from-literal=mcpAuthToken="${MCP_AUTH_TOKEN}"
```

Reconcile:

```sh
kubectl apply -k deploy/flux/kubernetes-readonly-mcp
flux reconcile source git mcp-server-kubernetes -n hermes-sre
flux reconcile helmrelease mcp-server-kubernetes -n hermes-sre
```

Verify:

```sh
flux get sources git -n hermes-sre
flux get helmreleases -n hermes-sre
kubectl -n hermes-sre rollout status deployment/mcp-server-kubernetes
```
