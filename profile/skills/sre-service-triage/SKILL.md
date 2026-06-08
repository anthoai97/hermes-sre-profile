# SRE Service Triage

Use this skill when a developer asks about service count, service health, rollout state, deployment results, pod status, or why a deployed change is not visible.

## Read-Only Kubernetes MCP Scope

Use only the configured `kubernetes-readonly` MCP server. Do not use terminal commands, filesystem tools, web tools, Helm CLI, Argo CD CLI, Docker CLI, cloud CLI, or any other MCP server.

Allowed MCP tools are:

- `kubectl_get`
- `kubectl_describe`
- `kubectl_logs`
- `kubectl_context`
- `explain_resource`
- `list_api_resources`
- `ping`

Do not restart, scale, patch, delete, apply, roll back, deploy, edit, or modify anything. Do not inspect Secrets or ConfigMaps. Do not use exec, attach, copy, port-forward, generic kubectl, Helm, or cleanup tools even if an MCP server exposes them.

Do not install, download, bootstrap, or configure tools. If the Kubernetes MCP server or a required readonly tool is missing, report the missing prerequisite and stop.

If the user asks for remediation, secret/config access, pod execution, or tool installation, provide only read-only non-sensitive findings and an escalation note.

## Kubernetes Checks

For "how many services are running":

Use `kubectl_get` through the `kubernetes-readonly` MCP server for deployments, statefulsets, daemonsets, running pods, and services across namespaces.

Use these read-only results to summarize counts by namespace and distinguish Kubernetes `Service` objects from application workloads.

For "is service A running":

Use `kubectl_get` for workloads, services, pods, endpoints, and endpoint slices. Use `kubectl_describe` for the target deployment or workload.

Answer with existence, desired replicas, available replicas, pod readiness, restarts, endpoint presence, and age.

Do not use `-o yaml` or `-o json` on broad resources unless needed for non-sensitive fields. Avoid output that can include environment variables, projected volumes, or secret/config references.

For "what happened after deploy":

Use `kubectl_describe` for rollout and deployment evidence, `kubectl_get` for events sorted by time when supported, and `kubectl_logs` for recent deployment or pod logs.

Look for image changes, failed pulls, readiness probe failures, CrashLoopBackOff, pending pods, scheduling failures, config errors, and old pods still serving.

## Answer Shape

Prefer this format:

```text
Status: <healthy | degraded | failing | unknown>
Answer: <direct answer>
Evidence:
- <read-only MCP tool call>: <key observation>
Next:
- <next read-only check or escalation note>
```

If evidence is incomplete, say what is missing instead of guessing.
