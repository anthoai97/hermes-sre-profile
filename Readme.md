# Hermes SRE Profile

Read-only Hermes Agent profile and deployment chart for SRE/DevOps support.

The profile is designed to answer simple developer questions about Kubernetes service health, rollout state, pod state, endpoints, and recent non-sensitive events while reducing manual SRE information gathering.

## What It Does

- Answers service status questions from live Kubernetes evidence.
- Provides a `/kubernetes_service_check` skill for simple readonly service checks.
- Uses the readonly Kubernetes MCP server for Kubernetes inspection.
- Refuses edit, delete, modify, restart, scale, patch, apply, rollback, exec, attach, copy, and port-forward actions.
- Does not inspect Kubernetes Secrets or ConfigMaps.
- Keeps memory disabled so new sessions do not reuse stale operational state.

Example questions:

```text
How many services are running in staging?
Is custody-service running in dev?
What happened with payment-api after my deployment?
I deployed service A, but nothing changed. What should I check?
/kubernetes_service_check Is custody-service running in dev?
/security_verify
```

## Contents

```text
profile/                   Hermes SRE profile distribution
charts/hermes-agent/       Helm chart for running Hermes in Kubernetes
local/                     Local Docker Compose development setup
mcp/                       MCP install setup; see `mcp/kubernetes-readonly/`
```

## Profile Install

From this repository:

```sh
git clone https://github.com/anthoai97/hermes-sre-profile.git
cd hermes-sre-profile
hermes profile install ./profile --alias
```

Configure runtime access in the installed profile `.env`:

```sh
OPENROUTER_API_KEY=
MCP_AUTH_TOKEN=
KUBERNETES_MCP_URL=http://mcp-server-kubernetes.hermes-sre.svc.cluster.local:3001/mcp
```

## Slack Team Onboarding

This profile supports team Slack usage through the Hermes messaging gateway. The Slack profile is configured for explicit mention usage:

```yaml
slack:
  require_mention: true
  strict_mention: true
```

In channels, users must mention the bot before it responds:

```text
@Hermes Agent is custody-service running in dev?
@Hermes Agent /kubernetes_service_check Is custody-service running in dev?
```

Follow the official Hermes Slack setup guide for the current Slack app manifest, scopes, Socket Mode setup, and troubleshooting:

```text
https://hermes-agent.nousresearch.com/docs/user-guide/messaging/slack
```

Recommended setup:

1. Generate the Slack app manifest:

   ```sh
   hermes slack manifest --write
   ```

2. In Slack, create a new app from the generated manifest at `https://api.slack.com/apps`.
3. Enable Socket Mode, install the app to the workspace, and copy:

   ```sh
   SLACK_BOT_TOKEN=xoxb-...
   SLACK_APP_TOKEN=xapp-...
   ```

4. Find authorized teammate Slack member IDs and set:

   ```sh
   SLACK_ALLOWED_USERS=U01ABC2DEF3,U04XYZ9ABC
   ```

5. Optionally restrict the bot to approved channels:

   ```sh
   SLACK_ALLOWED_CHANNELS=C0123456789,C0987654321
   ```

6. Optionally set the home channel for proactive gateway and scheduled delivery messages:

   ```sh
   SLACK_HOME_CHANNEL=C0123456789
   ```

7. Invite the bot to each allowed and home channel:

   ```text
   /invite @Hermes Agent
   ```

Never commit Slack tokens. Store them in local `.env` files or inject them through runtime secrets.

## Kubernetes MCP Scope

The agent expects the readonly Kubernetes MCP server to be available in the `hermes-sre` namespace:

```text
http://mcp-server-kubernetes.hermes-sre.svc.cluster.local:3001/mcp
```

Local Docker Compose can instead point `KUBERNETES_MCP_URL` at a host-side port-forward such as `http://host.docker.internal:3001/mcp`. The profile still sends the in-cluster Service name as the MCP `Host` header for DNS rebinding protection.

The profile enables only the generated Hermes MCP toolset `mcp-kubernetes-readonly` plus `skills`.

Do not grant:

- `secrets`
- `configmaps`
- `pods/exec`
- `pods/attach`
- `pods/portforward`
- mutating verbs such as `create`, `update`, `patch`, or `delete`

## Helm Chart

Install the readonly Kubernetes MCP server first:

```sh
export MCP_AUTH_TOKEN="<choose-a-long-random-token>"
./mcp/install-kubernetes-readonly.sh
```

Install:

```sh
helm upgrade --install hermes ./charts/hermes-agent \
  -n hermes-sre \
  --create-namespace \
  --set-string "global.mcpAuthToken=${MCP_AUTH_TOKEN}" \
  -f values.local.yaml
```

The chart deploys Hermes in Kubernetes, installs this profile from GitHub during pod bootstrap, and then runs Hermes with the installed profile:

```text
git clone --depth 1 https://github.com/anthoai97/hermes-sre-profile.git hermes-sre-profile
hermes profile install hermes-sre-profile/profile --alias --yes
hermes --profile sre-agent gateway run
```

It does not install `kubectl`, does not deploy the MCP server, and does not create Kubernetes RBAC for the Hermes agent pod. The separately installed readonly MCP server owns Kubernetes RBAC. Provide the same MCP auth token to Hermes through `global.mcpAuthToken`:

```yaml
global:
  mcpAuthToken: "<choose-a-long-random-token>"
```

The profile directory remains the source of truth for `profile/config.yaml`, `profile/SOUL.md`, and `profile/skills/`. The chart should not vendor or duplicate profile files.

See [charts/hermes-agent/README.md](charts/hermes-agent/README.md) for chart details.

## Security Defaults

- No Kubernetes Secret access.
- No ConfigMap access.
- No pod exec/attach/port-forward access.
- No file, browser, web, terminal, or code execution toolsets in the Hermes profile.
- No persistent memory for cross-session operational facts.
- `/kubernetes_service_check` is a dedicated skill slash command for simple readonly service checks.
- `/security_verify` is a dedicated skill slash command that verifies the MCP tool surface is readonly and performs a harmless readonly positive-control check.

See [SOUL.md](profile/SOUL.md) for the full agent behavior policy.
