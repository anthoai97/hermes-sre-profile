#!/bin/sh

set -eu
cd "$(dirname "$0")"

KUBERNETES_MCP_URL="${KUBERNETES_MCP_URL:-http://host.docker.internal:3001/mcp}"

docker run --rm \
    -v ./hermes_data:/opt/data \
    -v ../profile:/profile:ro \
    hermes-agent:latest \
    hermes profile install /profile --alias --yes

# docker run --rm \
#     -v ./hermes_data:/opt/data \
#     hermes-agent:latest \
#     --profile sre-agent setup

docker run --rm \
    --env-file .env \
    -e KUBERNETES_MCP_URL="$KUBERNETES_MCP_URL" \
    -v ./hermes_data:/opt/data \
    hermes-agent:latest \
    --profile sre-agent skills opt-out --remove
