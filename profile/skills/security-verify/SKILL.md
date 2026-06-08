# Security Verify

Use this skill when the user runs `/security_verify` or asks to verify that the Hermes SRE Kubernetes access is readonly.

## Scope

Use only the configured `kubernetes-readonly` MCP server. Do not use terminal commands, filesystem tools, web tools, Helm CLI, Argo CD CLI, Docker CLI, cloud CLI, or any other MCP server.

Do not attempt forbidden actions. This check verifies the exposed MCP tool surface and performs only harmless readonly positive-control checks.

## Expected Readonly Tools

The `kubernetes-readonly` MCP server should expose these tools:

```text
kubectl_get
kubectl_describe
kubectl_logs
kubectl_context
explain_resource
list_api_resources
ping
```

## Forbidden Tools

The MCP server must not expose these tools:

```text
kubectl_apply
kubectl_delete
kubectl_create
kubectl_patch
kubectl_scale
kubectl_rollout
kubectl_generic
exec_in_pod
start_port_forward
stop_port_forward
install_helm_chart
upgrade_helm_chart
uninstall_helm_chart
cleanup
```

## Procedure

1. Inspect the available MCP tools for `kubernetes-readonly`.
2. Confirm expected readonly tools are present.
3. Confirm forbidden tools are absent.
4. Run one harmless readonly positive-control check, such as listing namespaces or pods with `kubectl_get`, or calling `ping`.
5. Do not inspect Secrets or ConfigMaps.
6. Do not run exec, attach, copy, port-forward, generic kubectl, Helm, apply, create, update, patch, scale, rollout, delete, uninstall, or cleanup tools.

## Answer Shape

```text
Status: <passed | failed | degraded>
Answer: <short security posture summary>
Evidence:
- <MCP tool surface check or readonly MCP call>: <key observation>
Failing Controls:
- <forbidden exposed tools, missing readonly tools, failed readonly check, or "none">
Next:
- <RBAC/MCP config change or escalation note>
```

Mark the test `passed` only when all expected readonly tools are present, all forbidden tools are absent, and the readonly positive-control check succeeds.
