# SRE DevOps Agent Profile

This Hermes profile distribution packages a read-only SRE/DevOps support agent for answering developer questions about platform state, service health, and deployments.

It is designed to reduce repetitive information gathering for SRE and DevOps teams. The agent uses read-only `kubectl` commands executed inside the Hermes pod and explains the evidence behind its answers.

## Example Questions

```text
How many services are running in staging?
Is custody-service running in dev?
What happened with payment-api after my deployment at 2026-06-04 10:15 ICT?
I deployed service A, but nothing changed. What should I check?
```

## Install

From a published git repo:

```sh
hermes profile install github.com/your-org/sre-devops-agent --alias
```

From this local directory while developing:

```sh
hermes profile install ./profiles/sre-devops-agent --alias
```

## Configure

Copy the generated example env file and fill in your model key:

```sh
cp ~/.hermes/profiles/sre-devops-agent/.env.EXAMPLE ~/.hermes/profiles/sre-devops-agent/.env
```

Required variable:

```sh
OPENROUTER_API_KEY=
```

Optional local LLM variables:

```sh
LOCAL_LLM_BASE_URL=http://localhost:8080/v1
LOCAL_LLM_MODEL=
```

Provider behavior:

- Primary: OpenRouter, `anthropic/claude-sonnet-4`
- Fallback 1: OpenAI Codex OAuth, `gpt-5-codex`
- Fallback 2: local llama.cpp/OpenAI-compatible endpoint, `custom:llmcpp`

Codex OAuth credentials are not stored in this profile config. Run `hermes model`, choose OpenAI Codex, and complete the ChatGPT OAuth flow for the installed profile.

The runtime environment needs `kubectl` available in the Hermes container. When running in Kubernetes, bind the Hermes pod service account to read-only RBAC so in-cluster `kubectl` can read workloads, pods, services, endpoints, events, and logs. Do not grant access to Secrets, ConfigMaps, or pod execution subresources such as `pods/exec`, `pods/attach`, and `pods/portforward`.

## Recommended Kubernetes RBAC

Use read-only permissions first. A practical starting point is:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: hermes-sre-readonly
rules:
  - apiGroups: [""]
    resources: ["namespaces", "pods", "services", "endpoints", "events"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["pods/log"]
    verbs: ["get"]
  - apiGroups: ["apps"]
    resources: ["deployments", "statefulsets", "daemonsets", "replicasets"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["batch"]
    resources: ["jobs", "cronjobs"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["networking.k8s.io"]
    resources: ["ingresses", "networkpolicies"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["events.k8s.io"]
    resources: ["events"]
    verbs: ["get", "list", "watch"]
```

Bind it to the service account used by the Hermes gateway in the target cluster.

## Tool Scope

The profile enables only:

```yaml
toolsets:
  - terminal
```

Slack and Telegram gateway toolsets are also restricted to terminal access. The profile prompt allows only read-only `kubectl` inspection and refuses edit/delete/modify/remediation actions, including `kubectl exec`, `attach`, `cp`, and `port-forward`.

## Run

```sh
sre-devops-agent chat
```

or:

```sh
hermes -p sre-devops-agent chat
```

## Platform Gateway

For Slack or Telegram, configure platform tokens in the installed profile `.env`, restrict allowed channels/chats in `config.yaml`, then run:

```sh
hermes --profile sre-devops-agent gateway run
```

The profile does not enable Hermes platform presets for Slack or Telegram. Gateway tool access is restricted to terminal-only read-only `kubectl` investigation.

## Update

After this distribution is published and changed:

```sh
hermes profile update sre-devops-agent
```

Hermes preserves local user-owned files such as `.env`, memories, sessions, logs, and local state.
