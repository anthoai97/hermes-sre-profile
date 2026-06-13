# Readonly Kubernetes MCP Server

This folder contains the readonly Helm values for the `anthoai97/mcp-server-kubernetes` fork.
The installer pulls the Helm chart from the fork's `main` branch by default.
The values pin the MCP server image to upstream release `v3.8.0`.
Release `v3.8.0` enables DNS rebinding protection by default, so the values allow the Hermes in-cluster Service host:

```text
mcp-server-kubernetes.hermes-sre.svc.cluster.local:3001
```

The fork chart clone is local development scratch space at `mcp/.worktrees/mcp-server-kubernetes`. It is ignored by git so this profile repo does not vendor the MCP server source. The install script creates that clone on first run.

Install or upgrade the MCP server in the `hermes-sre` namespace with the readonly values file. The profile uses this namespace in its internal service URL.

Validate the installer and readonly values before changing them:

```bash
./scripts/validate-kubernetes-mcp-install.sh
```

```bash
export MCP_AUTH_TOKEN="<choose-a-long-random-token>"

./mcp/install-kubernetes-readonly.sh
```

Equivalent direct Helm command:

```bash
helm upgrade --install mcp-server-kubernetes mcp/.worktrees/mcp-server-kubernetes/helm-chart \
  --namespace hermes-sre \
  --create-namespace \
  --values mcp/kubernetes-readonly/values.yaml \
  --set-string "env.MCP_AUTH_TOKEN=${MCP_AUTH_TOKEN}"
```

Wait for the readonly MCP deployment:

```bash
kubectl -n hermes-sre rollout status deployment/mcp-server-kubernetes
```

Uninstall the MCP server:

```bash
helm uninstall mcp-server-kubernetes --namespace hermes-sre
```

Port-forward the readonly MCP service:

```bash
kubectl -n hermes-sre port-forward svc/mcp-server-kubernetes 3001:3001
```

In another terminal, export the same MCP auth token:

```bash
export MCP_AUTH_TOKEN="<same-token-used-for-helm-install>"
```

Test the MCP endpoint:

```bash
curl -sS \
  -H "X-MCP-AUTH: ${MCP_AUTH_TOKEN}" \
  -H "Host: mcp-server-kubernetes.hermes-sre.svc.cluster.local:3001" \
  -H "Accept: application/json, text/event-stream" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' \
  http://localhost:3001/mcp
```

Connect an MCP client to the local port-forward:

```toml
[mcp_servers.kubernetes-readonly]
transport = "streamable-http"
url = "http://localhost:3001/mcp"
env_http_headers = { "X-MCP-AUTH" = "MCP_AUTH_TOKEN" }
headers = { "Host" = "mcp-server-kubernetes.hermes-sre.svc.cluster.local:3001" }
```

## MCP Client Setup

Keep the port-forward running:

```bash
kubectl -n hermes-sre port-forward svc/mcp-server-kubernetes 3001:3001
```

Export the auth token before starting your MCP client:

```bash
export MCP_AUTH_TOKEN="<same-token-used-for-helm-install>"
```

Configure the client with the local HTTP endpoint and both required headers:

```toml
[mcp_servers.kubernetes-readonly]
transport = "streamable-http"
url = "http://localhost:3001/mcp"
env_http_headers = { "X-MCP-AUTH" = "MCP_AUTH_TOKEN" }
headers = { "Host" = "mcp-server-kubernetes.hermes-sre.svc.cluster.local:3001" }
```

After connecting, verify that `kubernetes-readonly` exposes readonly tools such as `kubectl_get`, `kubectl_describe`, `kubectl_logs`, and `list_api_resources`.

If your client does not accept HTTP MCP URLs directly, configure an HTTP-capable bridge that forwards to `http://localhost:3001/mcp` with the `X-MCP-AUTH` and `Host` headers.
