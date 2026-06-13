# Kubernetes Install Runbook

Use this runbook to install Hermes SRE in Kubernetes with the readonly Kubernetes MCP server.

## Order of operations

Install the components in this order:

1. Install the readonly Kubernetes MCP server.
2. Wait for the MCP server rollout.
3. Install Hermes Agent with the same MCP auth token.
4. Wait for the Hermes rollout.
5. Port-forward the Hermes dashboard.
6. Run the readonly behavior smoke tests.

Hermes does not need direct Kubernetes API permissions in MCP-only mode. The Hermes chart creates a ServiceAccount for pod identity, but it does not create Role, ClusterRole, RoleBinding, or ClusterRoleBinding resources. Kubernetes API access belongs to the separately installed readonly MCP server.

## Before installing

Run the local validation checks:

```sh
./scripts/validate-kubernetes-mcp-install.sh
./scripts/validate-hermes-chart.sh
```

Choose one long random token and keep it out of git:

```sh
export MCP_AUTH_TOKEN="<choose-a-long-random-token>"
```

Use this same token for the MCP install and the Hermes install.

## Install the readonly MCP server

Install MCP first:

```sh
./mcp/install-kubernetes-readonly.sh
```

Wait for the MCP deployment:

```sh
kubectl -n hermes-sre rollout status deployment/mcp-server-kubernetes
```

The MCP service endpoint used by Hermes is:

```text
http://mcp-server-kubernetes.hermes-sre.svc.cluster.local:3001/mcp
```

The readonly MCP values pin the runtime image, use service account auth, preserve HTTP transport on port `3001`, allow the in-cluster MCP service host for DNS rebinding protection, and keep the RBAC surface readonly without Secrets or ConfigMaps.

## Prepare runtime secrets

Inject gateway and model credentials through your deployment pipeline or Kubernetes Secrets. Do not commit real credentials in Helm values files.

Example Slack secret:

```sh
kubectl -n hermes-sre create secret generic hermes-slack-env \
  --from-literal=SLACK_BOT_TOKEN="xoxb-..." \
  --from-literal=SLACK_APP_TOKEN="xapp-..." \
  --from-literal=SLACK_ALLOWED_USERS="U01ABC2DEF3,U04XYZ9ABC" \
  --from-literal=SLACK_ALLOWED_CHANNELS="C0123456789,C0987654321" \
  --from-literal=SLACK_HOME_CHANNEL="C0123456789"
```

Example local override file, ignored by git as `values.local.yaml`:

```yaml
envFrom:
  - secretRef:
      name: hermes-slack-env
```

Add other non-committed runtime environment references there as needed.

## Install Hermes Agent

Install Hermes second, passing the same MCP token at runtime:

```sh
helm upgrade --install hermes ./charts/hermes-agent \
  --namespace hermes-sre \
  --create-namespace \
  -f values.local.yaml \
  --set-string "global.mcpAuthToken=${MCP_AUTH_TOKEN}"
```

Wait for the Hermes deployment:

```sh
kubectl -n hermes-sre rollout status deployment/hermes-hermes-agent
```

The chart installs the SRE profile during pod bootstrap and starts:

```sh
hermes --profile sre-agent gateway run
```

## Access the dashboard

Port-forward the Hermes dashboard service:

```sh
kubectl -n hermes-sre port-forward svc/hermes-hermes-agent 9119:9119
```

Open:

```text
http://127.0.0.1:9119
```

## Smoke checks

After both rollouts pass, verify the live behavior:

1. Run `/security_verify` through Hermes and confirm only readonly Kubernetes tools are available.
2. Ask a simple Kubernetes service-check question through Hermes.
3. Confirm Secrets and ConfigMaps are not available through the MCP tool surface.
4. Confirm mutating, interactive, exec, attach, copy, and port-forward style Kubernetes actions remain unavailable.

Record the cluster context, commands, rollout output, and prompt results in the relevant GitHub issue before closing the live smoke-test work.
