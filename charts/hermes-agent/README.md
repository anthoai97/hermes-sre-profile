# Hermes Agent Helm Chart

This chart packages the Docker Compose service:

```yaml
image: nousresearch/hermes-agent:latest
command: gateway run
ports:
  - "9119:9119"
volumes:
  - ~/Code/hermes_data:/opt/data
environment:
  - HERMES_DASHBOARD=1
  - HERMES_DASHBOARD_INSECURE=1
resources:
  limits:
    memory: 4G
    cpus: "2.0"
```

## Install

```sh
helm install hermes ./charts/hermes-agent
```

By default, the chart installs the Hermes SRE profile from GitHub during pod bootstrap, then runs the gateway with that profile:

```yaml
profile:
  name: sre-agent
  install:
    enabled: true
    source: https://github.com/anthoai97/hermes-sre-profile.git
    path: profile
    alias: true
```

The bootstrap init container runs:

```sh
git clone --depth 1 https://github.com/anthoai97/hermes-sre-profile.git hermes-sre-profile
hermes profile install hermes-sre-profile/profile --alias --yes
```

The main container then runs:

```sh
hermes --profile sre-agent gateway run
```

## Readonly Kubernetes MCP

This chart does not install the Kubernetes MCP server. Install the readonly MCP server separately from the repository root:

```sh
export MCP_AUTH_TOKEN="<choose-a-long-random-token>"
./mcp/install-kubernetes-readonly.sh
```

The installed profile expects the MCP endpoint at:

```text
http://mcp-server-kubernetes.hermes-sre.svc.cluster.local:3001/mcp
```

Pass the same token to the Hermes chart:

```yaml
global:
  mcpAuthToken: "<choose-a-long-random-token>"
```

The MCP install values live in `mcp/kubernetes-readonly/values.yaml`. The installer pulls the Helm chart from `https://github.com/anthoai97/mcp-server-kubernetes.git` on `main` by default. The values pin the runtime image to `flux159/mcp-server-kubernetes:v3.8.0`, enable service account auth, and keep the MCP RBAC readonly without Secrets or ConfigMaps access.

## Access the dashboard

```sh
kubectl port-forward svc/hermes-hermes-agent 9119:9119
```

Open `http://127.0.0.1:9119`.

## Configure API keys

The chart supports Hermes' profile-based deployment model:

- the profile is installed into `HERMES_HOME`, defaulting to `/opt/data`
- the profile directory is the source of truth for `config.yaml`, `SOUL.md`, and `skills/`
- runtime environment variables for provider keys and tokens
- the chart can optionally write an extra `config.yaml` override, but this is disabled by default

By default, the chart does not vendor profile files into the Helm chart. The init container pulls the profile from:

```text
https://github.com/anthoai97/hermes-sre-profile.git, subdirectory `profile/`
```

If you need a chart-local config override, enable `config.enabled`. Prefer changing the profile directory instead when the setting belongs to the SRE profile:

```yaml
config:
  enabled: true
  data:
    model:
      provider: openai
      default: gpt-4o
      api_mode: chat_completions
    agent:
      max_turns: 90
```

To override the full file as raw YAML:

```yaml
config:
  raw: |-
    model:
      provider: openai
      default: gpt-4o
```

For provider keys, inject runtime environment variables from your own deployment pipeline. The chart does not render, mount, or reference Kubernetes Secret resources:

```yaml
env:
  - name: OPENAI_API_KEY
    value: ""
  - name: ANTHROPIC_API_KEY
    value: ""
```

Install with:

```sh
helm upgrade --install hermes ./charts/hermes-agent -n hermes-sre --create-namespace -f values.local.yaml
```

## Kubernetes MCP access

The Hermes profile expects the separately installed readonly Kubernetes MCP server at:

```text
http://mcp-server-kubernetes.hermes-sre.svc.cluster.local:3001/mcp
```

The Hermes profile enables the generated MCP toolset `mcp-kubernetes-readonly` and filters it to readonly Kubernetes tools.

Set `global.mcpAuthToken` to the same value used as `MCP_AUTH_TOKEN` when installing `mcp-server-kubernetes`.

## RBAC

Hermes does not need direct Kubernetes API permissions when using MCP-only mode. This chart does not create Role, ClusterRole, RoleBinding, or ClusterRoleBinding resources for the Hermes pod.

The Hermes pod still uses a Kubernetes ServiceAccount for identity, but that ServiceAccount has no chart-created Kubernetes API permissions. Kubernetes API permissions belong to the separately installed readonly MCP server.

## Runtime environment examples

OpenRouter:

```yaml
env:
  - name: OPENROUTER_API_KEY
    value: ""
```

OpenAI:

```yaml
env:
  - name: OPENAI_API_KEY
    value: ""
```

Anthropic:

```yaml
env:
  - name: ANTHROPIC_API_KEY
    value: ""
```

Custom OpenAI-compatible endpoint:

```yaml
env:
  - name: LOCAL_LLM_BASE_URL
    value: "http://vllm.default.svc.cluster.local:8000/v1"
  - name: LOCAL_LLM_MODEL
    value: "your-model-name"
  - name: CUSTOM_API_KEY
    value: ""
```

Model/provider routing belongs in the installed profile. The chart should only inject runtime environment needed by that profile.

The chart intentionally has no `envFile`, `createSecret`, or Secret reference example. Avoid putting real credentials in values files.

## Persistence

By default, the chart creates a `10Gi` PVC and mounts it at `/opt/data`.

To reuse an existing claim:

```yaml
persistence:
  existingClaim: hermes-data
```

## Local image usage

If you override the image with one built locally, make sure it is available to your Kubernetes runtime. For example, with kind:

```sh
kind load docker-image hermes-agent:latest
```
