#!/bin/sh

# Bootstrap the Hermes SRE profile and set up the SRE agent.
docker run --rm \
    -v ./hermes_devops_data:/opt/data \
    -v ../profile:/profile:ro \
    nousresearch/hermes-agent \
    profile install /profile --alias --yes

docker run --rm \
    -v ./hermes_devops_data:/opt/data \
    nousresearch/hermes-agent \
    --profile sre-agent setup

docker exec -it hermes hermes --profile sre-agent skills opt-out --remove
