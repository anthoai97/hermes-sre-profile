# Local Development for Hermes SRE Profile

## Local Secrets

Keep local secrets in `local/.env`. This file is ignored by git.

```sh
cp local/.env.example local/.env
```

Edit `local/.env` and fill only the secrets you need:

```sh
TELEGRAM_BOT_TOKEN=
TELEGRAM_ALLOWED_USERS=
MCP_AUTH_TOKEN=
KUBERNETES_MCP_URL=http://host.docker.internal:3001/mcp
```

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
