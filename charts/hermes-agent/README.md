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

To run the gateway with a fixed Hermes profile, set `profile.name`:

```yaml
profile:
  name: hermes-agent-default
```

This renders container args equivalent to:

```sh
hermes --profile hermes-agent-default gateway run
```

## Access the dashboard

```sh
kubectl port-forward svc/hermes-hermes-agent 9119:9119
```

Open `http://127.0.0.1:9119`.

## Configure API keys

The chart supports Hermes' non-interactive onboarding model:

- `config.yaml` for non-secret settings
- runtime environment variables for provider keys and tokens
- `config.yaml` is written into `HERMES_HOME`, defaulting to `/opt/data`

By default, the chart creates a ConfigMap and an init container writes:

```text
/opt/data/config.yaml
```

The default config is a general Hermes config:

```yaml
config:
  data:
    model:
      provider: openrouter
      default: anthropic/claude-sonnet-4
      base_url: ""
      api_mode: chat_completions
    agent:
      max_turns: 90
    terminal:
      timeout: 180
    compression:
      enabled: true
    memory:
      memory_enabled: true
      user_profile_enabled: true
```

To override the full file as raw YAML:

```yaml
config:
  raw: |-
    model:
      provider: openai
      default: gpt-4o
    terminal:
      timeout: 180
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
helm upgrade --install hermes ./charts/hermes-agent -f values.local.yaml
```

## Kubernetes read-only access

By default, the chart creates read-only RBAC for the Hermes service account so the pod can run in-cluster `kubectl` inspection commands.

```yaml
rbac:
  create: true
  clusterWide: true
```

This grants `get`, `list`, and `watch` for common workload and networking resources, plus `get` for `pods/log`. It does not grant access to Kubernetes Secrets, ConfigMaps, `pods/exec`, `pods/attach`, or `pods/portforward`.

For namespace-only access:

```yaml
rbac:
  create: true
  clusterWide: false
```

To manage RBAC outside this chart:

```yaml
rbac:
  create: false
```

## Kubectl installation

By default, the chart installs `kubectl` at pod startup with an init container. This avoids maintaining a custom Hermes image.

```yaml
kubectl:
  enabled: true
  version: v1.30.14
  arch: amd64
  installPath: /opt/kubectl-bin
  verifyChecksum: true
  image:
    repository: curlimages/curl
    tag: 8.8.0
    pullPolicy: IfNotPresent
  securityContext:
    runAsUser: 0
    runAsNonRoot: false
```

The init container downloads:

```text
https://dl.k8s.io/release/<version>/bin/linux/<arch>/kubectl
```

When `kubectl.verifyChecksum=true`, it also downloads the matching `.sha256` file and validates the binary before making it executable. This matches the official Kubernetes Linux install flow.

It writes the binary to a shared `emptyDir`, and the Hermes container gets `PATH=/opt/kubectl-bin:/usr/local/bin:/usr/bin:/bin`.

Set `kubectl.arch` to `arm64` for ARM nodes.

Disable this when using an image that already contains `kubectl`:

```yaml
kubectl:
  enabled: false
```

## Provider examples

OpenRouter:

```yaml
config:
  data:
    model:
      provider: openrouter
      default: anthropic/claude-sonnet-4

env:
  - name: OPENROUTER_API_KEY
    value: ""
```

OpenAI:

```yaml
config:
  data:
    model:
      provider: openai
      default: gpt-4o

env:
  - name: OPENAI_API_KEY
    value: ""
```

Anthropic:

```yaml
config:
  data:
    model:
      provider: anthropic
      default: claude-sonnet-4-20250514

env:
  - name: ANTHROPIC_API_KEY
    value: ""
```

Custom OpenAI-compatible endpoint:

```yaml
config:
  data:
    model:
      provider: custom
      default: your-model-name
      base_url: http://vllm.default.svc.cluster.local:8000/v1
      api_key: "${CUSTOM_API_KEY}"

env:
  - name: CUSTOM_API_KEY
    value: ""
```

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
