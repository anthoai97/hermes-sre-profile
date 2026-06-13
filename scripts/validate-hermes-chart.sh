#!/usr/bin/env bash
set -euo pipefail

chart_dir="${CHART_DIR:-charts/hermes-agent}"
release_name="${RELEASE_NAME:-hermes}"
namespace="${NAMESPACE:-hermes-sre}"
test_token="${MCP_AUTH_TOKEN:-test-token}"
expected_mcp_url="http://mcp-server-kubernetes.hermes-sre.svc.cluster.local:3001/mcp"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

rendered="$tmp_dir/hermes-agent.yaml"

helm lint "$chart_dir"
helm template "$release_name" "$chart_dir" \
  --namespace "$namespace" \
  --set-string "global.mcpAuthToken=${test_token}" \
  > "$rendered"

require() {
  local pattern="$1"
  local description="$2"

  if ! grep -Eq -- "$pattern" "$rendered"; then
    echo "Missing expected chart output: $description" >&2
    exit 1
  fi
}

reject() {
  local pattern="$1"
  local description="$2"

  if grep -Eq -- "$pattern" "$rendered"; then
    echo "Unexpected chart output: $description" >&2
    exit 1
  fi
}

require '^kind: Deployment$' 'Deployment resource'
require '^kind: Service$' 'Service resource'
require '^kind: PersistentVolumeClaim$' 'PersistentVolumeClaim resource'
require '^kind: ServiceAccount$' 'ServiceAccount resource'

require 'name: bootstrap-hermes-home' 'profile bootstrap init container'
require 'git clone --depth 1 "\$profile_source" "\$workdir/repo"' 'profile git clone command'
require 'hermes profile install "\$workdir/repo/\$profile_path" --alias --yes' 'profile install command'
require 'https://github\.com/anthoai97/hermes-sre-profile\.git' 'profile source repository'

require '- --profile' 'Hermes profile arg'
require '- "sre-agent"' 'sre-agent profile name'
require '- gateway' 'gateway command arg'
require '- run' 'run command arg'

require 'name: KUBERNETES_MCP_URL' 'Kubernetes MCP URL env var'
require "$expected_mcp_url" 'in-cluster Kubernetes MCP URL'
require 'name: MCP_AUTH_TOKEN' 'MCP auth token env var'
require "value: \"$test_token\"" 'MCP auth token value from chart values'

require 'port: 9119' 'dashboard service port'
require 'containerPort: 9119' 'dashboard container port'

reject '^kind: (Role|ClusterRole|RoleBinding|ClusterRoleBinding)$' 'Hermes Kubernetes RBAC resources'

echo "Hermes chart validation passed."
