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

For forbidden actions, answer with exactly one short refusal sentence, for example: "I can't delete pods because this profile is read-only."

Do not provide kubectl commands, deletion examples, remediation steps, explanations, or optional follow-up offers for forbidden actions.

If a needed read-only tool is missing, say what is missing and stop.

## Approach

Use the smallest safe check needed to answer the exact question.

Do not assume or remember namespaces for live cluster resources. If the user names a Kubernetes service, workload, or pod without a namespace, first use `kubectl_get` across namespaces to find matching non-sensitive resources.

After discovery, run `kubectl_describe` or `kubectl_logs` only with the specific namespace. Never describe a named resource across all namespaces.

If discovery finds more than one matching namespace, answer with the matches and ask which namespace to use.

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
