# OpenClaw Claude Delegate

A reusable OpenClaw skill for running Claude Code as a **local delegated worker** with:

- dispatch, poll, result, and resume
- profile-based workdir scoping
- optional non-root runner execution
- self-heal hooks for Claude binary, auth sync, and runner-local acpx install

This is for the boring, reliable local wrapper lane, not the ACP chat-harness lane.

## Why this exists

Claude Code subscription access is valuable, but third-party harnesses cannot reliably use that subscription path directly. This wrapper gives any OpenClaw agent a clean delegation lane into local Claude Code without turning the whole runtime into a Claude-specific harness.

Use it when you want:
- a local Claude worker with monitoring and resume
- a bounded workdir instead of full-session sprawl
- a non-root runner model that survives OpenClaw updates better
- a way for other agents to delegate premium Claude work intentionally

## How it works

`claude-delegate` is a thin entrypoint over four layers:

1. `scripts/claude-delegate.sh` — command entrypoint and defaults
2. `scripts/cc-profile.sh` — resolves the chosen profile into a workdir and extra dirs
3. `scripts/cc-orchestrator.sh` — tracks tasks, logs, poll, result, and resume
4. `scripts/run-task.sh` — actually runs Claude, optionally through a non-root runner

If you enable the non-root path, `scripts/ensure-nonroot-delegation.sh` also syncs:
- Claude binary into the runner home
- Claude auth into the runner home
- acpx config into the runner home
- runner-local acpx install under `~/.local/share/clawd/vendor/acpx/`

## What is in this repo

- `SKILL.md` — the skill entrypoint
- `scripts/claude-delegate.sh` — stable wrapper command
- `scripts/cc-profile.sh` — profile-aware wrapper
- `scripts/cc-orchestrator.sh` — task registry, dispatch, poll, result, resume
- `scripts/run-task.sh` — low-level Claude runner
- `scripts/ensure-nonroot-delegation.sh` — non-root runner bootstrap/sync
- `references/setup.md` — setup and portability notes
- `profiles.json` — generic starter profiles

## When to use it

Use this when you want Claude Code to run as a local worker with explicit monitoring and resume support.

Do **not** use this when the user explicitly wants an ACP thread or chat harness. That is a different lane.

## Install options

### Option A, one-command bootstrap (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/StoicEnso/openclaw-claude-delegate/v0.2.2/install.sh | bash -s -- --version v0.2.2
```

This installs the skill into `~/.openclaw/skills/claude-delegate`, creates a `claude-delegate` CLI symlink in `~/.local/bin`, and runs a setup check.

### Option B, clone then install

```bash
git clone https://github.com/StoicEnso/openclaw-claude-delegate.git
cd openclaw-claude-delegate
bash install.sh
```

### Option C, npm/npx installer (package is publish-ready)

```bash
npx openclaw-claude-delegate
```

This will work once the npm package is published.

## Post-install sanity check

Run:

```bash
claude-delegate doctor
```

That shows:
- runner user
- runner home
- Claude binary path
- selected backend
- profile file in use
- root and runner Claude auth status
- a live Claude probe

## Quick start

If you used the installer and accepted the CLI link:

```bash
claude-delegate doctor
claude-delegate dispatch scratch 0.10 sonnet smoke "Reply with exactly CLAUDE-DELEGATE-SMOKE-OK"
claude-delegate list --all
claude-delegate result <task-id>
```

Repo-local form still works too:

```bash
bash scripts/claude-delegate.sh dispatch scratch 0.10 sonnet smoke "Reply with exactly CLAUDE-DELEGATE-SMOKE-OK"
bash scripts/claude-delegate.sh list --all
bash scripts/claude-delegate.sh result <task-id>
```

## Profiles

`profiles.json` is intentionally generic. For real deployments, either edit it or point to a host-local file:

```bash
export CLAUDE_DELEGATE_PROFILES=/abs/path/to/profiles.json
```

Profile paths support `~` and environment variable expansion like `${HOME}`.

## Non-root runner defaults

The wrapper defaults are tuned for a runner account like:

- `CLAUDE_RUNNER_USER=ccbot`
- `CLAUDE_RUNNER_HOME=/home/ccbot`
- `CLAUDE_BIN=/home/ccbot/.local/bin/claude`
- `CLAUDE_PERMISSION_MODE=bypassPermissions`
- `CLAUDE_BACKEND=cli`

Override those if your host layout differs.

## Prerequisites

Minimum:
- OpenClaw installed
- Claude Code installed and authenticated
- bash
- python3

For the full non-root self-heal path, you also want:
- npm
- sudo and permission to switch to the runner user
- a runner user such as `ccbot`

## Important reality checks

- `claude auth status` is **not** enough, use a real prompt probe.
- A plain completion test is **not** proof of tool-call compatibility.
- ACP and local CLI delegation are different products. Pick intentionally.

## License

MIT
