# Local Development for Hermes SRE Profile

## Local Secrets

Keep local secrets in `local/.env`. This file is ignored by git.

```sh
cp local/.env.example local/.env
```

Edit `local/.env` and fill only the secrets you need:

```sh
OPENROUTER_API_KEY=
TELEGRAM_BOT_TOKEN=
TELEGRAM_ALLOWED_USERS=
SLACK_BOT_TOKEN=
SLACK_APP_TOKEN=
SLACK_ALLOWED_USERS=
SLACK_ALLOWED_CHANNELS=
SLACK_HOME_CHANNEL=
MCP_AUTH_TOKEN=
KUBERNETES_MCP_URL=http://host.docker.internal:3001/mcp
```

## Local Slack Gateway

For Slack team usage, follow the official Hermes Slack guide:

```text
https://hermes-agent.nousresearch.com/docs/user-guide/messaging/slack
```

Generate the Slack app manifest, create the app in Slack, enable Socket Mode, then put the copied tokens and allowlists in `local/.env`:

```sh
hermes slack manifest --write
```

```sh
SLACK_BOT_TOKEN=xoxb-...
SLACK_APP_TOKEN=xapp-...
SLACK_ALLOWED_USERS=U01ABC2DEF3,U04XYZ9ABC
SLACK_ALLOWED_CHANNELS=C0123456789,C0987654321
SLACK_HOME_CHANNEL=C0123456789
```

The profile requires Slack mentions to start channel conversations, then allows follow-up replies in the same thread. Invite the bot to each allowed and home channel with `/invite @Hermes Agent`, then ask questions by mentioning it.

For local Docker, keep the readonly Kubernetes MCP port-forward running on the host:

```sh
kubectl -n hermes-sre port-forward svc/mcp-server-kubernetes 3001:3001
```

The container uses `host.docker.internal:3001` to reach that host port-forward. The profile sends the in-cluster Service name as the `Host` header required by MCP DNS rebinding protection.

Install the profile into the local Hermes data volume:

```sh
cd local
sh ./init.sh
```

Run compose from the `local` directory so `env_file: .env` resolves correctly:

```sh
docker compose up -d
```

The container runs the same profile command as the Helm chart:

```sh
hermes --profile sre-agent gateway run
```

Do not commit `local/.env`. If a token was ever committed in `docker-compose.yaml`, rotate it before continuing.
