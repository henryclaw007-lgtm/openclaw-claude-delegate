---
name: claude-delegate
description: "Run local Claude Code through a monitored wrapper with dispatch, poll, result, and resume, usually with a non-root runner user. Use when: you want a stable local Claude CLI worker lane in a bounded workspace, need resume/monitoring, or need Claude auth separate from OpenClaw providers. Don't use when: the user explicitly wants an ACP chat harness or thread, use acp-router plus sessions_spawn(runtime: \"acp\"); the task is a simple edit or shell command, use edit/exec directly; or the local Claude runner is not set up yet, read references/setup.md first."
---

# Claude Delegate

Use this skill when Claude Code should run as a **local delegated worker**, not as an ACP chat harness.

## Stable entrypoints

- Wrapper: `scripts/claude-delegate.sh`
- Profile wrapper: `scripts/cc-profile.sh`
- Orchestrator: `scripts/cc-orchestrator.sh`
- Low-level runner: `scripts/run-task.sh`

## Default flow

1. Read `references/setup.md` the first time you install or port this skill.
2. Configure `profiles.json`, or point `CLAUDE_DELEGATE_PROFILES` at a host-local profiles file.
3. Dispatch work through `scripts/claude-delegate.sh dispatch <profile> <budget> <model> <label> "<task>"`.
4. Monitor with `poll`, `result`, `list`, or `doctor`.
5. Use `resume` to continue the same Claude session instead of starting over.

## When to prefer this over ACP

Prefer this skill when you want:
- a boring local wrapper around Claude CLI
- a non-root runner user with synced auth/binary state
- bounded filesystem access through a chosen workdir
- cheap monitoring and resume without a chat-thread harness

Prefer ACP when the user explicitly asked for Claude Code as a chat/thread runtime.

## Files to load when needed

- Setup, auth, env knobs, and profile customization: `references/setup.md`

## Notes

- `scripts/cc-profile.sh` supports `CLAUDE_DELEGATE_PROFILES=/abs/path/to/profiles.json`.
- Profile paths support `~` and environment variable expansion.
- `scripts/ensure-nonroot-delegation.sh` supports env overrides for source paths if your Claude or acpx installs live somewhere else.
