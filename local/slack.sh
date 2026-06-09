#!/bin/sh

set -eu
cd "$(dirname "$0")"

docker run --rm \
    -e HOME=/opt/data \
    -e HERMES_HOME=/opt/data \
    -v ./hermes_data:/opt/data \
    hermes-agent:latest \
    hermes slack manifest --write

echo
echo "Slack manifest generated under local/hermes_data."
echo "Use it to create or update the Slack app at https://api.slack.com/apps."
