#!/usr/bin/env bash
set -euo pipefail

REPO_SLUG="${CLAUDE_DELEGATE_REPO:-henryclaw007-lgtm/openclaw-claude-delegate}"
VERSION="${CLAUDE_DELEGATE_VERSION:-main}"
SKILL_NAME="${CLAUDE_DELEGATE_SKILL_NAME:-claude-delegate}"
TARGET_DIR="${CLAUDE_DELEGATE_TARGET_DIR:-${OPENCLAW_SKILLS_DIR:-$HOME/.openclaw/skills}/$SKILL_NAME}"
BIN_DIR="${CLAUDE_DELEGATE_BIN_DIR:-$HOME/.local/bin}"
LINK_NAME="${CLAUDE_DELEGATE_LINK_NAME:-claude-delegate}"
FORCE=0
CREATE_LINK=1
RUN_SETUP_CHECK=1

usage() {
  cat <<USAGE
Install OpenClaw Claude Delegate

Usage:
  bash install.sh [options]

Options:
  --target <dir>       Install skill into this directory
  --bin-dir <dir>      Create CLI symlink in this directory (default: ~/.local/bin)
  --link-name <name>   CLI command name to create (default: claude-delegate)
  --no-link            Skip creating the global CLI symlink
  --no-check           Skip post-install setup check
  --force              Replace an existing install (backs it up first)
  --version <ref>      Install from GitHub ref when bootstrapping remotely (default: main)
  -h, --help           Show this help

Examples:
  bash install.sh
  bash install.sh --force
  curl -fsSL https://raw.githubusercontent.com/$REPO_SLUG/main/install.sh | bash
USAGE
}

log() { printf '[claude-delegate] %s\n' "$*"; }
fail() { printf '[claude-delegate] ERROR: %s\n' "$*" >&2; exit 1; }
need_cmd() { command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"; }

while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET_DIR="$2"; shift 2 ;;
    --bin-dir) BIN_DIR="$2"; shift 2 ;;
    --link-name) LINK_NAME="$2"; shift 2 ;;
    --no-link) CREATE_LINK=0; shift ;;
    --no-check) RUN_SETUP_CHECK=0; shift ;;
    --force) FORCE=1; shift ;;
    --version) VERSION="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) fail "Unknown option: $1" ;;
  esac
done

need_cmd bash
need_cmd python3
need_cmd tar

SCRIPT_PATH="${BASH_SOURCE[0]:-}"
SCRIPT_DIR=""
if [ -n "$SCRIPT_PATH" ] && [ -e "$SCRIPT_PATH" ]; then
  SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd -P)"
fi

cleanup() {
  if [ -n "${TMP_DIR:-}" ] && [ -d "${TMP_DIR:-}" ]; then
    rm -rf "$TMP_DIR"
  fi
  return 0
}
trap cleanup EXIT

resolve_source_dir() {
  if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/SKILL.md" ] && [ -f "$SCRIPT_DIR/scripts/claude-delegate.sh" ]; then
    printf '%s\n' "$SCRIPT_DIR"
    return 0
  fi

  need_cmd curl
  TMP_DIR="$(mktemp -d)"
  local archive="$TMP_DIR/claude-delegate.tar.gz"
  local url
  if [ "$VERSION" = "main" ]; then
    url="https://codeload.github.com/$REPO_SLUG/tar.gz/refs/heads/main"
  else
    url="https://codeload.github.com/$REPO_SLUG/tar.gz/refs/tags/$VERSION"
  fi
  log "Downloading $url" >&2
  if curl --retry 3 --retry-all-errors --retry-delay 2 -fsSL "$url" -o "$archive"; then
    tar -xzf "$archive" -C "$TMP_DIR"
    find "$TMP_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1
    return 0
  fi

  if command -v git >/dev/null 2>&1; then
    local clone_dir="$TMP_DIR/repo"
    log "Archive download failed, falling back to git clone" >&2
    git clone --depth 1 --branch "$VERSION" "https://github.com/$REPO_SLUG.git" "$clone_dir" >/dev/null 2>&1 || fail "git clone fallback failed"
    printf '%s\n' "$clone_dir"
    return 0
  fi

  fail "Could not download installer source, and git is unavailable for fallback"
}

SOURCE_DIR="$(resolve_source_dir)"
[ -n "$SOURCE_DIR" ] || fail "Could not resolve source directory"
[ -f "$SOURCE_DIR/SKILL.md" ] || fail "Source is missing SKILL.md"
[ -f "$SOURCE_DIR/scripts/claude-delegate.sh" ] || fail "Source is missing scripts/claude-delegate.sh"

mkdir -p "$(dirname "$TARGET_DIR")"
if [ -e "$TARGET_DIR" ]; then
  if [ "$FORCE" -ne 1 ]; then
    fail "Target already exists: $TARGET_DIR (rerun with --force to back it up and replace it)"
  fi
  BACKUP_PATH="${TARGET_DIR}.bak.$(date +%Y%m%d-%H%M%S)"
  log "Backing up existing install to $BACKUP_PATH"
  mv "$TARGET_DIR" "$BACKUP_PATH"
fi

mkdir -p "$TARGET_DIR"
tar --exclude='.git' --exclude='node_modules' --exclude='.DS_Store' -C "$SOURCE_DIR" -cf - . | tar -xf - -C "$TARGET_DIR"

if [ "$CREATE_LINK" -eq 1 ]; then
  mkdir -p "$BIN_DIR"
  ln -sfn "$TARGET_DIR/scripts/claude-delegate.sh" "$BIN_DIR/$LINK_NAME"
  log "Linked CLI: $BIN_DIR/$LINK_NAME -> $TARGET_DIR/scripts/claude-delegate.sh"
  case ":$PATH:" in
    *":$BIN_DIR:"*) : ;;
    *) log "Warning: $BIN_DIR is not on PATH yet" ;;
  esac
fi

log "Installed skill to $TARGET_DIR"
if [ "$RUN_SETUP_CHECK" -eq 1 ]; then
  log "Running setup check"
  bash "$TARGET_DIR/scripts/setup.sh" --check-only || true
fi

cat <<DONE

Installed OpenClaw Claude Delegate.

Next:
  1. Edit profiles if needed:
     $TARGET_DIR/profiles.json
  2. Run doctor:
     bash $TARGET_DIR/scripts/claude-delegate.sh doctor
  3. Smoke test:
     bash $TARGET_DIR/scripts/claude-delegate.sh dispatch scratch 0.10 sonnet smoke "Reply with exactly CLAUDE-DELEGATE-SMOKE-OK"

If the CLI link was created, you can also run:
  $LINK_NAME doctor
DONE
