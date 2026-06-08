# Kubernetes Service Check

Use this skill for simple read-only Kubernetes service checks: service counts, whether a service/workload is running, pod status, rollout status, endpoints, and recent non-sensitive events.

Do not use this skill for incident RCA, deep timeline analysis, or broad troubleshooting. Keep those for a separate incident/RCA skill.

## Scope

Use only the configured `kubernetes-readonly` MCP server.

Allowed tools:

- `kubectl_get`
- `kubectl_describe`
- `kubectl_logs`
- `kubectl_context`
- `explain_resource`
- `list_api_resources`
- `ping`

Do not mutate anything. Do not inspect Secrets or ConfigMaps. Do not use exec, attach, copy, port-forward, generic kubectl, Helm, terminal, filesystem, browser, web, Docker, cloud CLI, or any other MCP server.

If a needed read-only tool is missing, say what is missing and stop.

## Approach

Use the smallest safe check needed to answer the exact question.

For simple count or status questions, answer with only the result.

For service/workload health, check only the relevant objects: workload, pods, service, endpoints, rollout state, recent events, or recent logs.

Avoid broad raw output and avoid `-o yaml` or `-o json` on broad resources unless needed for non-sensitive fields.

## Answer Style

Prefer one sentence.

Examples:

```text
There are 28 Services deployed in the default namespace.
```

```text
custody-service is running in dev with 3/3 replicas available.
```

Only include evidence or a next step when the user asks for details or the answer cannot be determined from the available read-only checks.
