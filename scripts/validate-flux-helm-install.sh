#!/usr/bin/env bash
set -euo pipefail

flux_dir="${FLUX_DIR:-deploy/flux}"
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
require '^  name: mcp-server-kubernetes$' 'MCP GitRepository source name'
require 'url: https://github.com/anthoai97/mcp-server-kubernetes.git' 'MCP GitRepository URL'
require 'url: https://github.com/anthoai97/hermes-sre-profile.git' 'GitRepository URL'
require 'branch: main' 'GitRepository branch'
require '^kind: HelmRelease$' 'Flux HelmRelease'
require '^  name: mcp-server-kubernetes$' 'MCP HelmRelease name'
require '^  name: hermes$' 'Hermes HelmRelease name'
require 'releaseName: mcp-server-kubernetes' 'MCP Helm release name'
require 'releaseName: hermes' 'Helm release name'
require 'targetNamespace: hermes-sre' 'Hermes target namespace'
require 'chart: ./helm-chart' 'MCP chart path'
require 'chart: ./charts/hermes-agent' 'local Hermes chart path'
require 'kind: GitRepository' 'HelmRelease GitRepository sourceRef kind'
require 'name: mcp-server-kubernetes' 'MCP sourceRef name'
require 'name: hermes-sre-profile' 'HelmRelease sourceRef name'
require 'dependsOn:' 'Hermes depends on MCP HelmRelease'
require 'name: KUBERNETES_MCP_URL' 'Kubernetes MCP URL env var'
require "$expected_mcp_url" 'in-cluster Kubernetes MCP URL'
require 'name: hermes-runtime-env' 'runtime env Secret reference'
require 'valuesFrom:' 'Helm valuesFrom block'
require 'kind: Secret' 'MCP auth Secret values source'
require 'name: hermes-mcp-auth' 'MCP auth Secret name'
require 'valuesKey: mcpAuthToken' 'MCP auth Secret key'
require 'targetPath: env.MCP_AUTH_TOKEN' 'MCP auth target MCP chart value'
require 'targetPath: global.mcpAuthToken' 'MCP auth target chart value'
require 'repository: flux159/mcp-server-kubernetes' 'MCP runtime image repository'
require 'tag: v3.8.0' 'MCP runtime image tag'
require 'mode: http' 'MCP HTTP transport'
require 'port: 3001' 'MCP service port'
require 'provider: serviceaccount' 'MCP service account kubeconfig provider'
require 'allowOnlyReadonly: true' 'MCP readonly tool filter'
require 'allowOnlyNonDestructive: true' 'MCP non-destructive tool filter'
require 'useLegacyRules: false' 'MCP legacy wildcard RBAC disabled'
require 'DNS_REBINDING_ALLOWED_HOST: mcp-server-kubernetes.hermes-sre.svc.cluster.local:3001' 'MCP DNS rebinding host'

reject '^kind: Secret$' 'committed Kubernetes Secret resource'
reject "mcpAuthToken: *[\"']?[A-Za-z0-9_-]{16,}" 'literal MCP auth token'
reject 'resources:.*(secrets|configmaps)' 'Secrets or ConfigMaps in MCP RBAC resources'
reject '^- (secrets|configmaps)$' 'Secrets or ConfigMaps in MCP RBAC resource list'
reject 'verbs:.*(create|update|patch|delete|deletecollection|escalate|bind|impersonate)' 'mutating or privilege-expanding MCP RBAC verbs'

echo "Flux Helm install validation passed."
