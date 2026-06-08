# Local Development for Hermes SRE Profile

## Local Secrets

Keep local secrets in `local/.env`. This file is ignored by git.

```sh
cp local/.env.example local/.env
```

Edit `local/.env` and fill only the secrets you need:

```sh
OPENROUTER_API_KEY=
ANTHROPIC_API_KEY=
OPENAI_API_KEY=
TELEGRAM_BOT_TOKEN=
TELEGRAM_ALLOWED_USERS=
MCP_AUTH_TOKEN=
```

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
