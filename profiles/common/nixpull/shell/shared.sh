# shellcheck shell=bash
set -euo pipefail

CONFIG=${NIXPULL_CONFIG:?NIXPULL_CONFIG is required}
STATE_ROOT=$(jq -r '.stateRoot' "$CONFIG")
SUDO=/run/wrappers/bin/sudo
HOSTNAME=${NIXPULL_HOSTNAME:-hostname}
if [ "$(id -u)" -ne 0 ]; then
  STATE_ROOT=${XDG_STATE_HOME:-$HOME/.local/state}/nixpull
fi
BUILDER_DIR="$STATE_ROOT/builder"
CLIENT_DIR="$STATE_ROOT/client"
BUILDER_STATE="$BUILDER_DIR/state.json"
CLIENT_STATE="$CLIENT_DIR/state.json"
BUILDER_LOG="$BUILDER_DIR/log"
CLIENT_LOG="$CLIENT_DIR/log"

log_line() {
  local file=$1
  shift
  mkdir -p "$(dirname "$file")" || return
  printf '%s %s\n' "$(date --iso-8601=seconds)" "$*" >>"$file"
}

cleanup_build_workdir() {
  if [ -n "${NIXPULL_BUILD_WORKDIR:-}" ]; then
    mkdir -p "$BUILDER_DIR/logs"
    cp "$NIXPULL_BUILD_WORKDIR"/*.log "$BUILDER_DIR/logs/" 2>/dev/null || true
    rm -rf "$NIXPULL_BUILD_WORKDIR"
  fi
}

atomic_write() {
  local target=$1 tmp
  tmp=$(mktemp "${target}.XXXXXX") || return
  cat >"$tmp"
  chmod 0644 "$tmp"
  mv "$tmp" "$target"
}

root_published_profile() {
  local host=$1 path=$2 root_dir=/nix/var/nix/gcroots/nixpull tmp
  mkdir -p "$root_dir"
  tmp=$(mktemp -u "$root_dir/$host.XXXXXX")
  ln -s "$path" "$tmp"
  mv -T "$tmp" "$root_dir/$host"
}

hostname_short() {
  "$HOSTNAME" -s
}

current_system() {
  readlink /run/current-system 2>/dev/null || true
}

run_activation() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  else
    "$SUDO" "$@"
  fi
}

require_root() {
  local command=$1
  if [ "$(id -u)" -ne 0 ]; then
    printf 'nixpull: %s must be run as root; use sudo nixpull %s\n' "$command" "$command" >&2
    return 77
  fi
}

dispatch_remote_build() {
  local remote current
  remote=$(jq -r '.remoteBuilder // empty' "$CONFIG")
  [ -n "$remote" ] || return 1
  current=$(hostname_short)
  [ "$current" != "$remote" ] || return 1

  exec ssh "$remote" /run/current-system/sw/bin/nixpull build
}

escalate_build() {
  exec "$SUDO" /run/current-system/sw/bin/nixpull build
}

lock_hash() {
  local flake=$1
  local lock=$flake/flake.lock
  if [ -f "$lock" ]; then
    nix hash file "$lock" 2>/dev/null || sha256sum "$lock" | cut -d ' ' -f 1
  else
    printf ''
  fi
}

source_metadata() {
  local flake=$1 rev branch dirty
  rev=$(git -C "$flake" rev-parse HEAD 2>/dev/null || true)
  branch=$(git -C "$flake" branch --show-current 2>/dev/null || true)
  if ! git -C "$flake" diff --quiet --ignore-submodules HEAD 2>/dev/null; then
    dirty=true
  else
    dirty=false
  fi
  jq -n \
    --arg gitRev "$rev" \
    --arg gitBranch "$branch" \
    --argjson dirty "$dirty" \
    --arg lockHash "$(lock_hash "$flake")" \
    '{gitRev: $gitRev, gitBranch: $gitBranch, dirty: $dirty, lockHash: $lockHash}'
}

ensure_builder_state() {
  mkdir -p "$BUILDER_DIR"
  if [ ! -f "$BUILDER_STATE" ]; then
    atomic_write "$BUILDER_STATE" <<<'{"published":{},"lastBuild":null}'
  fi
}

ensure_client_state() {
  mkdir -p "$CLIENT_DIR"
  if [ ! -f "$CLIENT_STATE" ]; then
    if [ "$(id -u)" -ne 0 ] && [ -r /var/lib/nixpull/client/state.json ]; then
      cp /var/lib/nixpull/client/state.json "$CLIENT_STATE"
    else
      jq -n --arg host "$(hostname_short)" '{host: $host, fetched: null, lastPull: null}' | atomic_write "$CLIENT_STATE"
    fi
  fi
}

