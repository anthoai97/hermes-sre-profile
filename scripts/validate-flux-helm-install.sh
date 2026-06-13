#!/usr/bin/env bash
set -euo pipefail

flux_dir="${FLUX_DIR:-deploy/flux/hermes-agent}"
expected_mcp_url="http://mcp-server-kubernetes.hermes-sre.svc.cluster.local:3001/mcp"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

rendered="$tmp_dir/flux-hermes.yaml"

kubectl kustomize "$flux_dir" > "$rendered"

require() {
  local pattern="$1"
  local description="$2"

  if ! grep -Eq -- "$pattern" "$rendered"; then
    echo "Missing expected Flux output: $description" >&2
    exit 1
  fi
}

reject() {
  local pattern="$1"
  local description="$2"

  if grep -Eq -- "$pattern" "$rendered"; then
    echo "Unexpected Flux output: $description" >&2
    exit 1
  fi
}

require '^kind: Namespace$' 'hermes-sre Namespace'
require '^  name: hermes-sre$' 'hermes-sre namespace name'
require '^kind: GitRepository$' 'Flux GitRepository source'
require 'url: https://github.com/anthoai97/hermes-sre-profile.git' 'GitRepository URL'
require 'branch: main' 'GitRepository branch'
require '^kind: HelmRelease$' 'Flux HelmRelease'
require '^  name: hermes$' 'Hermes HelmRelease name'
require 'releaseName: hermes' 'Helm release name'
require 'targetNamespace: hermes-sre' 'Hermes target namespace'
require 'chart: ./charts/hermes-agent' 'local Hermes chart path'
require 'kind: GitRepository' 'HelmRelease GitRepository sourceRef kind'
require 'name: hermes-sre-profile' 'HelmRelease sourceRef name'
require 'name: KUBERNETES_MCP_URL' 'Kubernetes MCP URL env var'
require "$expected_mcp_url" 'in-cluster Kubernetes MCP URL'
require 'name: hermes-runtime-env' 'runtime env Secret reference'
require 'valuesFrom:' 'Helm valuesFrom block'
require 'kind: Secret' 'MCP auth Secret values source'
require 'name: hermes-mcp-auth' 'MCP auth Secret name'
require 'valuesKey: mcpAuthToken' 'MCP auth Secret key'
require 'targetPath: global.mcpAuthToken' 'MCP auth target chart value'

reject '^kind: Secret$' 'committed Kubernetes Secret resource'
reject "mcpAuthToken: *[\"']?[A-Za-z0-9_-]{16,}" 'literal MCP auth token'

echo "Flux Helm install validation passed."
