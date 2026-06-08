# MCP Integrations

This directory contains support files for MCP servers used by the Hermes SRE profile.

```text
kubernetes-readonly/        Local readonly Kubernetes MCP values and setup docs
install-kubernetes-readonly.sh
.worktrees/                 Ignored local upstream/fork checkouts
```

Install the readonly Kubernetes MCP server before installing the Hermes chart:

```bash
export MCP_AUTH_TOKEN="<choose-a-long-random-token>"
./mcp/install-kubernetes-readonly.sh
```

The installer pulls the Helm chart from `https://github.com/anthoai97/mcp-server-kubernetes.git` on `main` by default. Override `MCP_REPO_URL` or `MCP_REPO_REF` if you need another source.

The Hermes SRE profile expects the readonly Kubernetes MCP endpoint at:

```text
http://mcp-server-kubernetes.hermes-sre.svc.cluster.local:3001/mcp
```

Do not commit local MCP worktrees or secret-bearing values files.
