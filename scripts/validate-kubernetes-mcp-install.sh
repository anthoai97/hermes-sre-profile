#!/usr/bin/env bash
set -euo pipefail

installer="${INSTALLER:-mcp/install-kubernetes-readonly.sh}"
values_file="${MCP_VALUES_FILE:-mcp/kubernetes-readonly/values.yaml}"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

require_file() {
  local file="$1"
  local pattern="$2"
  local description="$3"

  if ! grep -Eq -- "$pattern" "$file"; then
    echo "Missing expected configuration: $description" >&2
    exit 1
  fi
}

reject_file() {
  local file="$1"
  local pattern="$2"
  local description="$3"

  if grep -Eq -- "$pattern" "$file"; then
    echo "Unexpected configuration: $description" >&2
    exit 1
  fi
}

if env -u MCP_AUTH_TOKEN "$installer" > "$tmp_dir/stdout" 2> "$tmp_dir/stderr"; then
  echo "Installer succeeded without MCP_AUTH_TOKEN." >&2
  exit 1
fi

require_file "$tmp_dir/stderr" '^MCP_AUTH_TOKEN is required\.$' 'missing-token error message'
require_file "$tmp_dir/stderr" "MCP_AUTH_TOKEN='<choose-a-long-random-token>'" 'missing-token usage example'

require_file "$installer" 'release_name="\$\{MCP_RELEASE_NAME:-mcp-server-kubernetes\}"' 'default MCP release name'
require_file "$installer" 'namespace="\$\{MCP_NAMESPACE:-hermes-sre\}"' 'default MCP namespace'
require_file "$installer" 'repo_url="\$\{MCP_REPO_URL:-https://github\.com/anthoai97/mcp-server-kubernetes\.git\}"' 'default MCP chart repository'
require_file "$installer" 'repo_ref="\$\{MCP_REPO_REF:-main\}"' 'default MCP chart ref'
require_file "$installer" 'chart_dir="\$\{MCP_CHART_DIR:-\$\{repo_dir\}/helm-chart\}"' 'default MCP chart directory'
require_file "$installer" 'values_file="\$\{MCP_VALUES_FILE:-mcp/kubernetes-readonly/values.yaml\}"' 'default MCP values file'
require_file "$installer" 'helm upgrade --install "\$release_name" "\$chart_dir"' 'Helm upgrade/install command'
require_file "$installer" '--namespace "\$namespace"' 'Helm namespace flag'
require_file "$installer" '--create-namespace' 'Helm namespace creation flag'
require_file "$installer" '--values "\$values_file"' 'Helm values file flag'
require_file "$installer" '--set-string "env.MCP_AUTH_TOKEN=\$\{MCP_AUTH_TOKEN\}"' 'MCP auth token Helm value'

require_file "$values_file" 'repository: flux159/mcp-server-kubernetes' 'MCP runtime image repository'
require_file "$values_file" 'tag: "v3\.8\.0"' 'MCP runtime image pin'
require_file "$values_file" 'mode: "http"' 'HTTP transport mode'
require_file "$values_file" 'port: 3001' 'MCP service port'
require_file "$values_file" 'targetPort: 3001' 'MCP service target port'
require_file "$values_file" 'provider: "serviceaccount"' 'service account kubeconfig provider'
require_file "$values_file" 'allowOnlyNonDestructive: true' 'non-destructive tool filter'
require_file "$values_file" 'allowOnlyReadonly: true' 'readonly tool filter'
require_file "$values_file" 'allowedTools: ""' 'no custom broad tool allowlist'
require_file "$values_file" 'create: true' 'service account and RBAC creation enabled'
require_file "$values_file" 'automount: true' 'service account token automount enabled'
require_file "$values_file" 'useLegacyRules: false' 'legacy wildcard RBAC disabled'
require_file "$values_file" 'DNS_REBINDING_ALLOWED_HOST: "mcp-server-kubernetes.hermes-sre.svc.cluster.local:3001"' 'DNS rebinding allowed host'
require_file "$values_file" 'resources: \["pods", "services", "endpoints", "persistentvolumeclaims", "namespaces", "nodes"\]' 'core readonly resources excluding sensitive objects'
require_file "$values_file" 'verbs: \["get", "list", "watch"\]' 'readonly Kubernetes verbs'

reject_file "$values_file" 'resources: \[.*(secrets|configmaps)' 'Secrets or ConfigMaps in active RBAC resources'
reject_file "$values_file" 'verbs: \[.*(create|update|patch|delete|deletecollection|escalate|bind|impersonate)' 'mutating or privilege-expanding RBAC verbs'

echo "Readonly Kubernetes MCP install validation passed."
