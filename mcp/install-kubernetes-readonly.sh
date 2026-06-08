#!/usr/bin/env bash
set -euo pipefail

release_name="${MCP_RELEASE_NAME:-mcp-server-kubernetes}"
namespace="${MCP_NAMESPACE:-hermes-sre}"
repo_dir="${MCP_REPO_DIR:-mcp/.worktrees/mcp-server-kubernetes}"
repo_url="${MCP_REPO_URL:-https://github.com/anthoai97/mcp-server-kubernetes.git}"
repo_ref="${MCP_REPO_REF:-main}"
chart_dir="${MCP_CHART_DIR:-${repo_dir}/helm-chart}"
values_file="${MCP_VALUES_FILE:-mcp/kubernetes-readonly/values.yaml}"

if [[ -z "${MCP_AUTH_TOKEN:-}" ]]; then
  echo "MCP_AUTH_TOKEN is required." >&2
  echo "Example: MCP_AUTH_TOKEN='<choose-a-long-random-token>' $0" >&2
  exit 1
fi

if [[ ! -d "$chart_dir" ]]; then
  mkdir -p "$(dirname "$repo_dir")"
  git clone --depth 1 --branch "$repo_ref" "$repo_url" "$repo_dir"
fi

helm upgrade --install "$release_name" "$chart_dir" \
  --namespace "$namespace" \
  --create-namespace \
  --values "$values_file" \
  --set-string "env.MCP_AUTH_TOKEN=${MCP_AUTH_TOKEN}"
