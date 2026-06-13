# AGENTS.md

Guidance for AI coding agents working in this repository.

## Rules
- Do not over-engineer.
- Aim for simplicity and elegance of implementation.
- Make minimal edits.
- Always read the whole file when you open it.
- Read `CONTEXT.md` at the start of every session to understand the project instead of starting from scratch.
- Update `CONTEXT.md` after a large code update; keep `CONTEXT.md` concise.
- Break larger work into phases. Run agents sequentially (one phase at a time) and commit after each phase, so progress stays clear and reviewable.
- Spawn agents to manage your context better, but run them one at a time rather than in parallel.
- Do not add `Co-Authored-By` or any AI attribution to commit messages.

## Agent skills

### Issue tracker

Issues and PRDs are tracked in GitHub Issues for `anthoai97/hermes-sre-profile`. See `docs/agents/issue-tracker.md`.

### Triage labels

Use the default triage label vocabulary: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

This is a single-context repo: read root `CONTEXT.md` and relevant ADRs under `docs/adr/` when present. See `docs/agents/domain.md`.
