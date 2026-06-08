# Project Context

Hermes SRE is a Hermes Agent profile for simple readonly Kubernetes service checks through a readonly Kubernetes MCP server.

Hermes Agent docs: `https://hermes-agent.nousresearch.com/docs/`

The profile source of truth is under `profile/`:

- `profile/distribution.yaml`
- `profile/config.yaml`
- `profile/SOUL.md`
- `profile/skills/`

The Helm chart under `charts/hermes-agent/` only deploys Hermes in Kubernetes. It does not vendor profile files or skills. The chart bootstrap init container installs the profile from GitHub with:

```sh
git clone --depth 1 https://github.com/anthoai97/hermes-sre-profile.git hermes-sre-profile
hermes profile install hermes-sre-profile/profile --alias --yes
```

The runtime command is:

```sh
hermes --profile sre-agent gateway run
```

The readonly MCP server is expected at:

```text
http://mcp-server-kubernetes.hermes-sre.svc.cluster.local:3001/mcp
```

The profile reads that endpoint from `KUBERNETES_MCP_URL` and sends `mcp-server-kubernetes.hermes-sre.svc.cluster.local:3001` as the HTTP `Host` header. Local Docker Compose defaults `KUBERNETES_MCP_URL` to `http://host.docker.internal:3001/mcp` so the container can use a host-side `kubectl port-forward`.

MCP setup lives in `mcp/kubernetes-readonly/`. Local MCP upstream or fork checkouts live under ignored `mcp/.worktrees/`.

The Hermes chart does not deploy the MCP server and does not include a Kubernetes MCP subchart. Install the MCP server separately with `./mcp/install-kubernetes-readonly.sh`, then install Hermes with the same token through `global.mcpAuthToken`. The MCP installer pulls the Helm chart from `https://github.com/anthoai97/mcp-server-kubernetes.git` on `main` by default. The MCP install values pin the runtime image to `flux159/mcp-server-kubernetes:v3.8.0`, and DNS rebinding protection allows `mcp-server-kubernetes.hermes-sre.svc.cluster.local:3001` by default.

Keep secrets out of git. Use local `.env` files or runtime env injection for `OPENROUTER_API_KEY`, `MCP_AUTH_TOKEN`, and other profile secrets.
