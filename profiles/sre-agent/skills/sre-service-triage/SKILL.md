# SRE Service Triage

Use this skill when a developer asks about service count, service health, rollout state, deployment results, pod status, or why a deployed change is not visible.

## Read-Only Kubectl Scope

Use only terminal commands that run read-only `kubectl` inspection. Do not use filesystem tools, web tools, Helm CLI, Argo CD CLI, Docker CLI, cloud CLI, or MCP servers.

Do not restart, scale, patch, delete, apply, roll back, deploy, edit, or modify anything. Do not inspect Secrets or ConfigMaps. Do not run `kubectl exec`, `kubectl attach`, `kubectl cp`, `kubectl port-forward`, or any command that opens a shell/process in a pod. If the user asks for remediation, secret/config access, or pod execution, provide only read-only non-sensitive findings and an escalation note.

## Kubernetes Checks

For "how many services are running":

```sh
kubectl get deploy,statefulset,daemonset -A
kubectl get pods -A --field-selector=status.phase=Running
kubectl get svc -A
```

Use these read-only results to summarize counts by namespace and distinguish Kubernetes `Service` objects from application workloads.

For "is service A running":

```sh
kubectl get deploy,statefulset,daemonset,svc,pods -A
kubectl describe deploy -n <namespace> <deployment>
kubectl get pods -n <namespace> -l <selector> -o wide
kubectl get endpoints,endpointslice -n <namespace>
```

Answer with existence, desired replicas, available replicas, pod readiness, restarts, endpoint presence, and age.

Do not use `-o yaml` or `-o json` on broad resources unless needed for non-sensitive fields. Avoid output that can include environment variables, projected volumes, or secret/config references.

For "what happened after deploy":

```sh
kubectl rollout status deploy/<deployment> -n <namespace>
kubectl rollout history deploy/<deployment> -n <namespace>
kubectl describe deploy/<deployment> -n <namespace>
kubectl get events -n <namespace> --sort-by=.lastTimestamp
kubectl logs -n <namespace> deploy/<deployment> --since=30m
```

Look for image changes, failed pulls, readiness probe failures, CrashLoopBackOff, pending pods, scheduling failures, config errors, and old pods still serving.

## Answer Shape

Prefer this format:

```text
Status: <healthy | degraded | failing | unknown>
Answer: <direct answer>
Evidence:
- <read-only kubectl command>: <key observation>
Next:
- <next read-only check or escalation note>
```

If evidence is incomplete, say what is missing instead of guessing.
