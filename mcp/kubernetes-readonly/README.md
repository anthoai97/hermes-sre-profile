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

Port-forward the readonly MCP service:

```bash
kubectl -n hermes-sre port-forward svc/mcp-server-kubernetes 3001:3001
```

In another terminal, export the same MCP API key:

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

## Claude Setup

Keep the port-forward running:

```bash
kubectl -n hermes-sre port-forward svc/mcp-server-kubernetes 3001:3001
```

Export the auth token before starting Claude:

```bash
export MCP_AUTH_TOKEN="<same-token-used-for-helm-install>"
```

Add the readonly Kubernetes MCP server to Claude Code:

```bash
claude mcp add \
  --transport http \
  --scope user \
  kubernetes-readonly \
  http://localhost:3001/mcp \
  --header "X-MCP-AUTH: ${MCP_AUTH_TOKEN}" \
  --header "Host: mcp-server-kubernetes.hermes-sre.svc.cluster.local:3001"
```

Verify it is registered:

```bash
claude mcp list
claude mcp get kubernetes-readonly
```

Inside Claude Code, run:

```text
/mcp
```

Then check that `kubernetes-readonly` is connected and exposes readonly tools such as `kubectl_get`, `kubectl_describe`, `kubectl_logs`, and `list_api_resources`.

Alternative JSON setup for Claude Code:

```bash
claude mcp add-json kubernetes-readonly \
  '{"type":"http","url":"http://localhost:3001/mcp","headers":{"X-MCP-AUTH":"'"${MCP_AUTH_TOKEN}"'","Host":"mcp-server-kubernetes.hermes-sre.svc.cluster.local:3001"}}'
```

Claude Desktop note: if `claude_desktop_config.json` does not accept HTTP MCP URLs directly, use Claude Code for this local port-forward setup or configure a stdio bridge such as `mcp-remote` that forwards to `http://localhost:3001/mcp` with the `X-MCP-AUTH` and `Host` headers.
