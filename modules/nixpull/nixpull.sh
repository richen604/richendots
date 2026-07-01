# shellcheck shell=bash
set -euo pipefail

CONFIG=${NIXPULL_CONFIG:?NIXPULL_CONFIG is required}
STATE_ROOT=$(jq -r '.stateRoot' "$CONFIG")
BUILDER_DIR="$STATE_ROOT/builder"
CLIENT_DIR="$STATE_ROOT/client"
BUILDER_STATE="$BUILDER_DIR/state.json"
CLIENT_STATE="$CLIENT_DIR/state.json"
BUILDER_LOG="$BUILDER_DIR/log"
CLIENT_LOG="$CLIENT_DIR/log"

usage() {
  cat <<EOF
nixpull - pull-based NixOS profile updates

usage: nixpull <build|fetch|pull|status|check> [options]

commands:
  build        build and publish configured host profiles (builder)
  fetch        copy latest published profile for this host, never activate
  pull [-a]    fetch, then activate latest published profile
  status       show local and published state
  check        compare published state without copying or activating
EOF
}

log_line() {
  local file=$1
  shift
  mkdir -p "$(dirname "$file")"
  printf '%s %s\n' "$(date --iso-8601=seconds)" "$*" >>"$file"
}

atomic_write() {
  local target=$1 tmp
  tmp=$(mktemp "${target}.XXXXXX")
  cat >"$tmp"
  chmod 0644 "$tmp"
  mv "$tmp" "$target"
}

require_role() {
  local expected=$1 actual
  actual=$(jq -r '.role' "$CONFIG")
  if [ "$actual" != "$expected" ]; then
    printf 'nixpull: command requires %s role, configured role is %s\n' "$expected" "$actual" >&2
    exit 2
  fi
}

hostname_short() {
  hostname -s
}

ssh_args() {
  jq -r '.server.sshOptions[]?' "$CONFIG"
  printf -- '-p\n%s\n' "$(jq -r '.server.port' "$CONFIG")"
}

ssh_target() {
  printf '%s@%s' "$(jq -r '.server.user' "$CONFIG")" "$(jq -r '.server.host' "$CONFIG")"
}

server_online() {
  mapfile -t args < <(ssh_args)
  ssh "${args[@]}" "$(ssh_target)" true >/dev/null 2>&1
}

read_remote_builder_state() {
  mapfile -t args < <(ssh_args)
  # shellcheck disable=SC2029
  ssh "${args[@]}" "$(ssh_target)" "cat '$BUILDER_STATE'" 2>/dev/null
}

current_system() {
  readlink /run/current-system 2>/dev/null || true
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
    jq -n --arg host "$(hostname_short)" '{host: $host, fetched: null, lastPull: null}' | atomic_write "$CLIENT_STATE"
  fi
}

build_one_host() {
  local flake=$1 host=$2 cores=$3 outdir=$4
  local log=$outdir/$host.log
  local activatable toplevel generation
  local cores_args=()
  if [ "$cores" != "null" ]; then
    cores_args=(--cores "$cores")
  fi

  {
    printf 'building %s\n' "$host"
    activatable=$(nix build "$flake#nixpullProfiles.$host" --print-out-paths --no-link "${cores_args[@]}")
    toplevel=$(nix build "$flake#nixosConfigurations.$host.config.system.build.toplevel" --print-out-paths --no-link "${cores_args[@]}")
    generation=$(date +%s)
    jq -n \
      --arg host "$host" \
      --arg generation "$generation" \
      --arg activatablePath "$activatable" \
      --arg toplevelPath "$toplevel" \
      --arg builtAt "$(date --iso-8601=seconds)" \
      --slurpfile source "$outdir/source.json" \
      '{host: $host, generation: ($generation | tonumber), activatablePath: $activatablePath, toplevelPath: $toplevelPath, builtAt: $builtAt} + $source[0]' >"$outdir/$host.json"
  } >"$log" 2>&1
}

cmd_build() {
  require_role builder
  ensure_builder_state

  local flake max_jobs cores workdir failures=0 successes=0 publish_partial
  flake=$(jq -r '.flake' "$CONFIG")
  max_jobs=$(jq -r '.build.maxJobs' "$CONFIG")
  cores=$(jq -r '.build.cores' "$CONFIG")
  publish_partial=$(jq -r '.build.publishPartial' "$CONFIG")
  workdir=$(mktemp -d "$BUILDER_DIR/build.XXXXXX")
  trap 'rm -rf "$workdir"' EXIT

  source_metadata "$flake" >"$workdir/source.json"
  mapfile -t hosts < <(jq -r '.build.hosts[]' "$CONFIG")
  printf 'building %s host(s) with maxJobs=%s\n' "${#hosts[@]}" "$max_jobs"
  log_line "$BUILDER_LOG" "build start hosts=${hosts[*]} maxJobs=$max_jobs"

  local running=0 host pid failed=0
  for host in "${hosts[@]}"; do
    build_one_host "$flake" "$host" "$cores" "$workdir" &
    pid=$!
    printf '%s\n' "$host" >"$workdir/pid-$pid"
    running=$((running + 1))
    if [ "$running" -ge "$max_jobs" ]; then
      if ! wait -n; then
        failed=1
      fi
      running=$((running - 1))
    fi
  done
  while [ "$running" -gt 0 ]; do
    if ! wait -n; then
      failed=1
    fi
    running=$((running - 1))
  done

  if [ "$publish_partial" != true ] && [ "$failed" -ne 0 ]; then
    log_line "$BUILDER_LOG" "build failed; publishPartial=false so no hosts published"
    printf 'one or more builds failed; no hosts published because publishPartial=false\n' >&2
    return 1
  fi

  local state new_state meta
  state=$(cat "$BUILDER_STATE")
  new_state=$state
  for host in "${hosts[@]}"; do
    if [ -f "$workdir/$host.json" ]; then
      meta=$(cat "$workdir/$host.json")
      new_state=$(jq --arg host "$host" --argjson meta "$meta" '.published[$host] = $meta' <<<"$new_state")
      successes=$((successes + 1))
      log_line "$BUILDER_LOG" "build success host=$host activatablePath=$(jq -r '.activatablePath' "$workdir/$host.json")"
      printf 'published %s\n' "$host"
    else
      failures=$((failures + 1))
      log_line "$BUILDER_LOG" "build failure host=$host log=$workdir/$host.log"
      printf 'failed %s\n' "$host" >&2
      sed 's/^/  /' "$workdir/$host.log" >&2 || true
    fi
  done

  jq \
    --arg builtAt "$(date --iso-8601=seconds)" \
    --argjson successes "$successes" \
    --argjson failures "$failures" \
    '.lastBuild = {builtAt: $builtAt, successes: $successes, failures: $failures}' \
    <<<"$new_state" | atomic_write "$BUILDER_STATE"

  log_line "$BUILDER_LOG" "build complete successes=$successes failures=$failures"
  [ "$failures" -eq 0 ]
}

fetch_metadata() {
  local host=$1 remote_state metadata
  if ! server_online; then
    printf 'nixpull: server %s unreachable; skipping fetch\n' "$(jq -r '.server.host' "$CONFIG")" >&2
    log_line "$CLIENT_LOG" "fetch skip server-unreachable"
    return 75
  fi
  remote_state=$(read_remote_builder_state) || {
    printf 'nixpull: unable to read remote builder state\n' >&2
    return 1
  }
  metadata=$(jq -e --arg host "$host" '.published[$host]' <<<"$remote_state") || {
    printf 'nixpull: no published build for %s\n' "$host" >&2
    return 1
  }
  printf '%s\n' "$metadata"
}

cmd_fetch() {
  require_role client
  ensure_client_state

  local host metadata activatable current_fetched store
  host=$(hostname_short)
  if ! metadata=$(fetch_metadata "$host"); then
    local rc=$?
    [ "$rc" -eq 75 ] && return 0
    return "$rc"
  fi
  activatable=$(jq -r '.activatablePath' <<<"$metadata")
  current_fetched=$(jq -r '.fetched.activatablePath // empty' "$CLIENT_STATE")
  if [ "$current_fetched" = "$activatable" ]; then
    printf 'already fetched %s\n' "$activatable"
    log_line "$CLIENT_LOG" "fetch noop host=$host activatablePath=$activatable"
  else
    store=$(jq -r '.server.store' "$CONFIG")
    nix copy --from "$store" "$activatable"
    log_line "$CLIENT_LOG" "fetch success host=$host activatablePath=$activatable"
    printf 'fetched %s\n' "$activatable"
  fi

  jq --arg host "$host" --argjson metadata "$metadata" '.host = $host | .fetched = $metadata' "$CLIENT_STATE" | atomic_write "$CLIENT_STATE"
}

activate_latest() {
  local metadata=$1 activatable args=()
  activatable=$(jq -r '.activatablePath' <<<"$metadata")
  mkdir -p "$(jq -r '.activation.tempPath' "$CONFIG")"
  args=(
    activate "$activatable"
    --profile-path /nix/var/nix/profiles/system
    --temp-path "$(jq -r '.activation.tempPath' "$CONFIG")"
    --confirm-timeout "$(jq -r '.activation.confirmTimeout' "$CONFIG")"
    --activation-timeout "$(jq -r '.activation.activationTimeout' "$CONFIG")"
  )
  case "$(jq -r '.activation.goal' "$CONFIG")" in
    switch) ;;
    boot) args+=(--boot) ;;
    test) args+=(--test) ;;
    dry-activate) args+=(--dry-activate) ;;
  esac
  [ "$(jq -r '.activation.magicRollback' "$CONFIG")" = true ] && args+=(--magic-rollback)
  [ "$(jq -r '.activation.autoRollback' "$CONFIG")" = true ] && args+=(--auto-rollback)
  "$activatable/activate-rs" "${args[@]}"
}

cmd_pull() {
  require_role client
  local ask=0
  case "${1:-}" in
    -a|--ask) ask=1 ;;
    "") ;;
    *) usage; exit 2 ;;
  esac

  local host metadata toplevel result
  host=$(hostname_short)
  if ! metadata=$(fetch_metadata "$host"); then
    local rc=$?
    log_line "$CLIENT_LOG" "pull failed fetch rc=$rc"
    return "$rc"
  fi
  cmd_fetch >/dev/null

  metadata=$(jq -c '.fetched' "$CLIENT_STATE")
  toplevel=$(jq -r '.toplevelPath' <<<"$metadata")
  if [ "$ask" -eq 1 ]; then
    if command -v dix >/dev/null 2>&1; then
      dix /run/current-system "$toplevel" || printf 'warning: dix failed; continuing to confirmation\n' >&2
    else
      printf 'warning: dix is not installed; skipping diff\n' >&2
    fi
    printf 'Activate %s? [y/N] ' "$(jq -r '.activatablePath' <<<"$metadata")"
    read -r answer
    case "$answer" in
      y|Y|yes|YES) ;;
      *)
        log_line "$CLIENT_LOG" "pull declined host=$host activatablePath=$(jq -r '.activatablePath' <<<"$metadata")"
        printf 'activation declined; fetched closure remains in the store\n'
        return 0
        ;;
    esac
  fi

  if activate_latest "$metadata"; then
    result=$(jq -n --arg status success --arg at "$(date --iso-8601=seconds)" --arg activatablePath "$(jq -r '.activatablePath' <<<"$metadata")" '{status: $status, at: $at, activatablePath: $activatablePath}')
    jq --argjson result "$result" '.lastPull = $result' "$CLIENT_STATE" | atomic_write "$CLIENT_STATE"
    log_line "$CLIENT_LOG" "pull success host=$host activatablePath=$(jq -r '.activatablePath' <<<"$metadata")"
    printf 'activated %s\n' "$(jq -r '.activatablePath' <<<"$metadata")"
  else
    local rc=$?
    result=$(jq -n --arg status failure --arg at "$(date --iso-8601=seconds)" --argjson exitCode "$rc" --arg activatablePath "$(jq -r '.activatablePath' <<<"$metadata")" '{status: $status, at: $at, exitCode: $exitCode, activatablePath: $activatablePath}')
    jq --argjson result "$result" '.lastPull = $result' "$CLIENT_STATE" | atomic_write "$CLIENT_STATE"
    log_line "$CLIENT_LOG" "pull failure host=$host rc=$rc activatablePath=$(jq -r '.activatablePath' <<<"$metadata")"
    return "$rc"
  fi
}

cmd_status() {
  local host published fetched last_pull
  host=$(hostname_short)
  printf 'host: %s\n' "$host"
  printf 'current: %s\n' "$(current_system)"
  if [ -f "$CLIENT_STATE" ]; then
    fetched=$(jq -r '.fetched.activatablePath // "none"' "$CLIENT_STATE")
    last_pull=$(jq -c '.lastPull // "none"' "$CLIENT_STATE")
    printf 'fetched: %s\n' "$fetched"
    printf 'lastPull: %s\n' "$last_pull"
  fi
  if [ "$(jq -r '.role' "$CONFIG")" = client ] && published=$(fetch_metadata "$host" 2>/dev/null); then
    printf 'published: %s\n' "$(jq -r '.activatablePath' <<<"$published")"
    printf 'publishedBuiltAt: %s\n' "$(jq -r '.builtAt' <<<"$published")"
  elif [ -f "$BUILDER_STATE" ]; then
    printf 'published hosts: %s\n' "$(jq -r '.published | keys | join(",")' "$BUILDER_STATE")"
    printf 'lastBuild: %s\n' "$(jq -c '.lastBuild' "$BUILDER_STATE")"
  else
    printf 'published: unavailable\n'
  fi
}

cmd_check() {
  require_role client
  local host metadata current fetched
  host=$(hostname_short)
  metadata=$(fetch_metadata "$host")
  current=$(current_system)
  fetched=$(jq -r '.fetched.activatablePath // empty' "$CLIENT_STATE" 2>/dev/null || true)
  printf 'published: %s\n' "$(jq -r '.activatablePath' <<<"$metadata")"
  printf 'fetched: %s\n' "${fetched:-none}"
  printf 'current: %s\n' "${current:-unknown}"
}

case "${1:-}" in
  build) shift; cmd_build "$@" ;;
  fetch) shift; cmd_fetch "$@" ;;
  pull) shift; cmd_pull "$@" ;;
  status) shift; cmd_status "$@" ;;
  check) shift; cmd_check "$@" ;;
  -h|--help|help) usage ;;
  *) usage; exit 2 ;;
esac
