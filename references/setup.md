# Claude Delegate setup

## What this package gives you

A local Claude Code delegation lane with:
- dispatch, poll, result, resume
- optional non-root runner execution
- profile-based workdir scoping
- runner self-heal for Claude binary, auth file, and acpx install when you use the provided ensure script
- a practical way for any OpenClaw agent to reach a locally authenticated Claude subscription worker

The real advantage is the **local delegated non-root `bypassPermissions` lane**. That is separate from ACP and exists because third-party harnesses do not reliably get Claude subscription access.

## Quick install

### Recommended bootstrap

```bash
curl -fsSL https://raw.githubusercontent.com/StoicEnso/openclaw-claude-delegate/v0.2.3/install.sh | bash -s -- --version v0.2.3
```

That installs the skill into `~/.openclaw/skills/claude-delegate`, creates `~/.local/bin/claude-delegate`, and runs a setup check.

### Clone/install flow

1. Install Claude Code and log in once.
2. Clone this repo.
3. Run `bash install.sh`.
4. Edit `profiles.json` for your project roots, or keep a host-local profiles file and export `CLAUDE_DELEGATE_PROFILES=/abs/path/to/profiles.json`.
5. If you want a non-root runner, set these as needed:
   - `CLAUDE_RUNNER_USER`
   - `CLAUDE_RUNNER_HOME`
   - `CLAUDE_BIN`
   - `CLAUDE_PERMISSION_MODE`
   - `CLAUDE_BACKEND`
6. Run `claude-delegate doctor` or `bash scripts/claude-delegate.sh doctor`.

## Install result

After a normal install you should have:
- skill folder: `~/.openclaw/skills/claude-delegate`
- CLI path: `~/.local/bin/claude-delegate`

If `~/.local/bin` is not on your `PATH`, add it in your shell profile.

## Stable commands

```bash
claude-delegate dispatch <profile> <budget> <model> <label> "<task>"
claude-delegate poll <task-id>
claude-delegate result <task-id>
claude-delegate resume <task-id> <budget> "<follow-up>"
claude-delegate list --all
claude-delegate doctor
```

Repo-local form:

```bash
bash scripts/claude-delegate.sh dispatch <profile> <budget> <model> <label> "<task>"
```

## Profiles

`cc-profile.sh` reads `profiles.json` next to the skill by default.

Override it per host:

```bash
export CLAUDE_DELEGATE_PROFILES=/abs/path/to/profiles.json
```

Path values inside profiles support:
- `~`
- `${HOME}` and other environment variables

## Non-root runner notes

`ensure-nonroot-delegation.sh` is the boring path when you want root-owned OpenClaw to launch Claude as another user.

It can sync these from a source install into the runner account:
- Claude binary
- Claude auth file
- acpx config
- runner-local acpx install

If your host uses different source paths, override them before calling the wrapper:
- `OPENCLAW_ACPX_PACKAGE`
- `ROOT_CLAUDE_LINK`
- `ROOT_CLAUDE_CREDS`
- `ROOT_ACPX_CONFIG`
- `DEFAULT_ACPX_SPEC`

## ACP vs delegate lane

Do not blur these together:

- **ACP** is the OpenClaw chat/thread harness lane
- **Claude Delegate** is the local Claude CLI wrapper lane

If you want the non-root `bypassPermissions` worker path, use **Claude Delegate**.
Do not assume ACP automatically inherits that execution model.

## What not to assume

- A healthy `claude auth status` is not enough. Run a real prompt probe.
- A plain text completion test does not prove tool-call compatibility.
- ACP and local CLI delegation are different lanes. Pick one on purpose.

## Recommended sanity checks

1. `bash scripts/setup.sh --check-only`
2. `bash scripts/claude-delegate.sh doctor`
3. `bash scripts/claude-delegate.sh dispatch scratch 0.10 sonnet smoke "Reply with exactly CLAUDE-DELEGATE-SMOKE-OK"`
4. `bash scripts/claude-delegate.sh result <task-id>`

## npm / npx note

This repo now includes `package.json` and a small installer bin so it is npm-publish ready. The intended command is:

```bash
npx openclaw-claude-delegate
```

That package still needs to be published to npm before this command works for the public.

## Packaging note

This skill intentionally keeps host-specific profiles outside the core workflow. For open-source sharing, keep the skill generic and put personal repo paths in your local `CLAUDE_DELEGATE_PROFILES` file.
