# OpenClaw Claude Delegate

A reusable OpenClaw skill for running Claude Code as a **local delegated worker** with:

- dispatch, poll, result, and resume
- profile-based workdir scoping
- optional non-root runner execution
- self-heal hooks for Claude binary, auth sync, and runner-local acpx install

This is for the boring, reliable local wrapper lane, not the ACP chat-harness lane.

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

## Quick install

### Option A, one-command bootstrap (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/henryclaw007-lgtm/openclaw-claude-delegate/main/install.sh | bash
```

This installs the skill into `~/.openclaw/skills/claude-delegate`, creates a `claude-delegate` CLI symlink in `~/.local/bin`, and runs a setup check.

### Option B, clone then install

```bash
git clone https://github.com/henryclaw007-lgtm/openclaw-claude-delegate.git
cd openclaw-claude-delegate
bash install.sh
```

### Option C, npm/npx installer (package is publish-ready)

```bash
npx openclaw-claude-delegate
```

This will work once the npm package is published.

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
