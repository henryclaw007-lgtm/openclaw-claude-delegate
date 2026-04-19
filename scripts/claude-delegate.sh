#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_ROOT="${SCRIPT_DIR%/scripts}"
PROFILE_WRAPPER="$SCRIPT_DIR/cc-profile.sh"
ORCHESTRATOR="$SCRIPT_DIR/cc-orchestrator.sh"
RUN_TASK="$SCRIPT_DIR/run-task.sh"

export CLAUDE_RUNNER_USER="${CLAUDE_RUNNER_USER:-ccbot}"
export CLAUDE_RUNNER_HOME="${CLAUDE_RUNNER_HOME:-/home/ccbot}"
export CLAUDE_BIN="${CLAUDE_BIN:-/home/ccbot/.local/bin/claude}"
export CLAUDE_PERMISSION_MODE="${CLAUDE_PERMISSION_MODE:-bypassPermissions}"
export CLAUDE_BACKEND="${CLAUDE_BACKEND:-cli}"
export CLAUDE_DELEGATE_PROFILES="${CLAUDE_DELEGATE_PROFILES:-$SKILL_ROOT/profiles.json}"
export CLAUDE_DELEGATE_BOOTSTRAP="${CLAUDE_DELEGATE_BOOTSTRAP:-1}"
export CLAUDE_DELEGATE_DOC_BASENAME="${CLAUDE_DELEGATE_DOC_BASENAME:-CLAUDE.delegate.md}"

usage() {
  cat <<'EOF'
Usage:
  claude-delegate.sh dispatch <profile> <budget> <model> <label> "<task>" [cc-profile options]
  claude-delegate.sh poll <task-id>
  claude-delegate.sh result [--text|--raw] <task-id>
  claude-delegate.sh resume <task-id> <budget> "<follow-up>" [resume options]
  claude-delegate.sh list [--running|--done|--failed|--all]
  claude-delegate.sh cancel <task-id>
  claude-delegate.sh costs [--today|--all]
  claude-delegate.sh cleanup
  claude-delegate.sh doctor
  claude-delegate.sh profile <raw cc-profile args...>
  claude-delegate.sh orchestrator <raw cc-orchestrator args...>
  claude-delegate.sh run-task <raw run-task args...>
EOF
}

doctor() {
  local acpx_bin="${CLAUDE_RUNNER_HOME}/.local/share/clawd/vendor/acpx"
  cat <<EOF
runner_user=$CLAUDE_RUNNER_USER
runner_home=$CLAUDE_RUNNER_HOME
claude_bin=$CLAUDE_BIN
backend=$CLAUDE_BACKEND
permission_mode=$CLAUDE_PERMISSION_MODE
profiles_file=$CLAUDE_DELEGATE_PROFILES
acpx_cache_root=$acpx_bin
delegate_bootstrap=$CLAUDE_DELEGATE_BOOTSTRAP
delegate_doc_basename=$CLAUDE_DELEGATE_DOC_BASENAME
EOF
  echo
  echo "[root claude auth status]"
  /root/.local/bin/claude auth status || true
  echo
  echo "[runner claude auth status]"
  sudo -u "$CLAUDE_RUNNER_USER" -H env HOME="$CLAUDE_RUNNER_HOME" "$CLAUDE_BIN" auth status || true
  echo
  echo "[runner live probe]"
  timeout 30 sudo -u "$CLAUDE_RUNNER_USER" -H env HOME="$CLAUDE_RUNNER_HOME" "$CLAUDE_BIN" -p "Reply with exactly CLAUDE-DELEGATE-PROBE-OK" || true
}

cmd="${1:-}"
shift || true

case "$cmd" in
  dispatch)
    profile="${1:-}"
    [ -n "$profile" ] || { usage >&2; exit 1; }
    shift
    exec bash "$PROFILE_WRAPPER" "$profile" dispatch "$@"
    ;;
  poll|result|resume|list|cancel|costs|cleanup)
    exec bash "$ORCHESTRATOR" "$cmd" "$@"
    ;;
  doctor)
    doctor
    ;;
  profile)
    exec bash "$PROFILE_WRAPPER" "$@"
    ;;
  orchestrator)
    exec bash "$ORCHESTRATOR" "$@"
    ;;
  run-task)
    exec bash "$RUN_TASK" "$@"
    ;;
  ""|-h|--help|help)
    usage
    ;;
  *)
    echo "Unknown command: $cmd" >&2
    usage >&2
    exit 1
    ;;
esac
