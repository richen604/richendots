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

usage() {
  cat <<EOF
nixpull - pull-based NixOS profile updates

usage: nixpull <build|fetch|pull|activate|status|check> [options]

commands:
  build [FLAKE] build configured host profiles from FLAKE (defaults to configured flake)
  fetch        copy latest published profile for this host, never activate
  pull [-a]    fetch, then activate latest published profile
  activate     activate the already fetched profile (privilege is requested only for activation)
  status       show local and published state
  check        compare published state without copying or activating
EOF
}

log_line() {
  local file=$1
  shift
  mkdir -p "$(dirname "$file")" || return
  printf '%s %s\n' "$(date --iso-8601=seconds)" "$*" >>"$file"
}

trigger_webhook() {
  local host=$1 webhook url token_file token curl_args=()
  webhook=$(jq -c --arg host "$host" '.build.fetchWebhooks[$host] // empty' "$CONFIG")
  [ -n "$webhook" ] || return 0

  url=$(jq -r '.url' <<<"$webhook")
  token_file=$(jq -r '.tokenFile' <<<"$webhook")
  if [ -r "$token_file" ]; then
    token=$(tr -d '\r\n' <"$token_file")
    curl_args=(-H "Authorization: Bearer $token")
  else
    log_line "$BUILDER_LOG" "webhook skipped host=$host reason=missing-token-file tokenFile=$token_file"
    return 0
  fi

  if curl --fail --silent --show-error --location --max-time 10 -X POST "${curl_args[@]}" "$url" >/dev/null; then
    log_line "$BUILDER_LOG" "webhook success host=$host url=$url"
  else
    log_line "$BUILDER_LOG" "webhook failure host=$host url=$url"
  fi
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
  chmod 0664 "$tmp"
  mv "$tmp" "$target"
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

build_one_host() {
  local flake=$1 host=$2 cores=$3 outdir=$4
  local log=$outdir/$host.log
  local activatable toplevel generation
  local paths=()
  local cores_args=()
  if [ "$cores" != "null" ]; then
    cores_args=(--cores "$cores")
  fi

  : >"$log"
  print_build_host "$host"
  mapfile -t paths < <(nom_build_store_paths "$log" "$flake#nixpullProfiles.$host" "$flake#nixosConfigurations.$host.config.system.build.toplevel" "${cores_args[@]}")
  activatable=${paths[0]:-}
  toplevel=${paths[1]:-}
  if [ -z "$activatable" ] || [ -z "$toplevel" ]; then
    printf 'nixpull: nom did not report both store paths for %s\n' "$host" >&2
    return 1
  fi
  generation=$(date +%s)
  jq -n \
    --arg host "$host" \
    --arg generation "$generation" \
    --arg activatablePath "$activatable" \
    --arg toplevelPath "$toplevel" \
    --arg builtAt "$(date --iso-8601=seconds)" \
    --slurpfile source "$outdir/source.json" \
    '{host: $host, generation: ($generation | tonumber), activatablePath: $activatablePath, toplevelPath: $toplevelPath, builtAt: $builtAt} + $source[0]' >"$outdir/$host.json"
}

publish_available_hosts() {
  local workdir=$1 state=$2 host meta marker published=0
  local new_state=$state
  local published_hosts=()
  shift 2
  for host in "$@"; do
    marker=$workdir/$host.published
    if [ -f "$workdir/$host.json" ] && [ ! -f "$marker" ]; then
      meta=$(cat "$workdir/$host.json")
      new_state=$(jq --arg host "$host" --argjson meta "$meta" '.published[$host] = $meta' <<<"$new_state")
      log_line "$BUILDER_LOG" "build success host=$host activatablePath=$(jq -r '.activatablePath' "$workdir/$host.json")"
      print_build_published "$host"
      : >"$marker"
      published_hosts+=("$host")
      published=1
    fi
  done
  if [ "$published" -eq 1 ]; then
    printf '%s\n' "$new_state" | atomic_write "$BUILDER_STATE"
    for host in "${published_hosts[@]}"; do
      trigger_webhook "$host"
    done
  fi
}

cmd_build() {
  local flake_override=""
  case "${1:-}" in
    -h|--help|help)
      usage
      return 0
      ;;
    "") ;;
    *)
      flake_override=$1
      shift
      ;;
  esac
  if [ "$#" -ne 0 ]; then
    printf 'nixpull: build accepts at most one flake path\n' >&2
    return 2
  fi

  ensure_builder_state

  local flake max_jobs cores workdir failures=0 successes=0 publish_partial
  flake=${flake_override:-$(jq -r '.flake' "$CONFIG")}
  max_jobs=$(jq -r '.build.maxJobs' "$CONFIG")
  cores=$(jq -r '.build.cores' "$CONFIG")
  publish_partial=$(jq -r '.build.publishPartial' "$CONFIG")
  workdir=$(mktemp -d "$BUILDER_DIR/build.XXXXXX")
  NIXPULL_BUILD_WORKDIR=$workdir
  trap cleanup_build_workdir EXIT

  source_metadata "$flake" >"$workdir/source.json"
  mapfile -t hosts < <(jq -r '.build.hosts[]' "$CONFIG")
  print_build_start "${#hosts[@]}" "$max_jobs"
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
      if [ "$publish_partial" = true ]; then
        publish_available_hosts "$workdir" "$(cat "$BUILDER_STATE")" "${hosts[@]}"
      fi
    fi
  done
  while [ "$running" -gt 0 ]; do
    if ! wait -n; then
      failed=1
    fi
    running=$((running - 1))
    if [ "$publish_partial" = true ]; then
      publish_available_hosts "$workdir" "$(cat "$BUILDER_STATE")" "${hosts[@]}"
    fi
  done

  if [ "$publish_partial" != true ] && [ "$failed" -ne 0 ]; then
    log_line "$BUILDER_LOG" "build failed; publishPartial=false so no hosts published"
    printf 'one or more builds failed; no hosts published because publishPartial=false\n' >&2
    return 1
  fi

  local state new_state meta trigger_hosts=()
  state=$(cat "$BUILDER_STATE")
  new_state=$state
  for host in "${hosts[@]}"; do
    if [ -f "$workdir/$host.json" ]; then
      successes=$((successes + 1))
      if [ "$publish_partial" != true ]; then
        meta=$(cat "$workdir/$host.json")
        new_state=$(jq --arg host "$host" --argjson meta "$meta" '.published[$host] = $meta' <<<"$new_state")
        log_line "$BUILDER_LOG" "build success host=$host activatablePath=$(jq -r '.activatablePath' "$workdir/$host.json")"
        print_build_published "$host"
        trigger_hosts+=("$host")
      fi
    else
      failures=$((failures + 1))
      log_line "$BUILDER_LOG" "build failure host=$host log=$workdir/$host.log"
      print_build_failed "$host" >&2
      printf 'nixpull: build log retained at %s/logs/%s.log\n' "$BUILDER_DIR" "$host" >&2
    fi
  done

  jq \
    --arg builtAt "$(date --iso-8601=seconds)" \
    --argjson successes "$successes" \
    --argjson failures "$failures" \
    '.lastBuild = {builtAt: $builtAt, successes: $successes, failures: $failures}' \
    <<<"$new_state" | atomic_write "$BUILDER_STATE"

  for host in "${trigger_hosts[@]}"; do
    trigger_webhook "$host"
  done

  log_line "$BUILDER_LOG" "build complete successes=$successes failures=$failures"
  [ "$failures" -eq 0 ]
}

fetch_metadata() {
  local host=$1 remote_state metadata metadata_url
  metadata_url=$(jq -r '.server.metadataUrl' "$CONFIG")
  if ! remote_state=$(curl --fail --silent --show-error --location --connect-timeout 10 "$metadata_url"); then
    printf 'nixpull: metadata URL unreachable; skipping fetch: %s\n' "$metadata_url" >&2
    log_line "$CLIENT_LOG" "fetch skip server-unreachable"
    return 75
  fi
  metadata=$(jq -e --arg host "$host" '.published[$host]' <<<"$remote_state") || {
    printf 'nixpull: no published build for %s\n' "$host" >&2
    return 1
  }
  printf '%s\n' "$metadata"
}

fetch_closure() {
  local host=$1 metadata=$2 activatable current_fetched substituter
  activatable=$(jq -r '.activatablePath' <<<"$metadata")
  current_fetched=$(jq -r '.fetched.activatablePath // empty' "$CLIENT_STATE")
  if [ "$current_fetched" = "$activatable" ] && [ -x "$activatable/activate-rs" ]; then
    print_nixpull_event "already fetched" "$activatable"
    log_line "$CLIENT_LOG" "fetch noop host=$host activatablePath=$activatable"
  else
    substituter=$(jq -r '.server.substituterUrl' "$CONFIG")
    nix copy --from "$substituter" "$activatable"
    if [ ! -x "$activatable/activate-rs" ]; then
      printf 'nixpull: fetched path is missing executable activate-rs: %s\n' "$activatable" >&2
      log_line "$CLIENT_LOG" "fetch failure missing-activate-rs host=$host activatablePath=$activatable"
      return 1
    fi
    log_line "$CLIENT_LOG" "fetch success host=$host activatablePath=$activatable"
    print_nixpull_event "fetched" "$activatable"
  fi

  jq --arg host "$host" --argjson metadata "$metadata" '.host = $host | .fetched = $metadata | .fetching = null' "$CLIENT_STATE" | atomic_write "$CLIENT_STATE"
}

record_fetching() {
  local host=$1 metadata=$2 activatable current_fetched fetching
  activatable=$(jq -r '.activatablePath' <<<"$metadata")
  current_fetched=$(jq -r '.fetched.activatablePath // empty' "$CLIENT_STATE")
  [ "$current_fetched" != "$activatable" ] || return 0

  fetching=$(jq -n \
    --arg status fetching \
    --arg at "$(date --iso-8601=seconds)" \
    --argjson metadata "$metadata" \
    '{status: $status, at: $at, metadata: $metadata}')
  jq --arg host "$host" --argjson fetching "$fetching" '.host = $host | .fetching = $fetching' "$CLIENT_STATE" | atomic_write "$CLIENT_STATE"
}

record_fetch_failure() {
  local host=$1 metadata=$2 rc=$3 fetching
  fetching=$(jq -n \
    --arg status failure \
    --arg at "$(date --iso-8601=seconds)" \
    --argjson exitCode "$rc" \
    --argjson metadata "$metadata" \
    '{status: $status, at: $at, exitCode: $exitCode, metadata: $metadata}')
  jq --arg host "$host" --argjson fetching "$fetching" '.host = $host | .fetching = $fetching' "$CLIENT_STATE" | atomic_write "$CLIENT_STATE"
}

cmd_fetch() {
  ensure_client_state

  local host metadata
  host=$(hostname_short)
  if metadata=$(fetch_metadata "$host"); then
    :
  else
    local rc=$?
    [ "$rc" -eq 75 ] && return 0
    return "$rc"
  fi
  record_fetching "$host" "$metadata"
  fetch_closure "$host" "$metadata" || {
    local rc=$?
    record_fetch_failure "$host" "$metadata" "$rc"
    return "$rc"
  }
}

activate_latest() {
  local metadata=$1 activatable temp_path activation_timeout magic_rollback activate_pid store_name store_hash canary wait_log
  activatable=$(jq -r '.activatablePath' <<<"$metadata")
  temp_path=$(jq -r '.activation.tempPath' "$CONFIG")
  if [ "$(id -u)" -ne 0 ]; then
    temp_path="$STATE_ROOT/deploy-rs"
  fi
  activation_timeout=$(jq -r '.activation.activationTimeout' "$CONFIG")
  magic_rollback=$(jq -r '.activation.magicRollback' "$CONFIG")
  mkdir -p "$temp_path"

  local args=(
    activate "$activatable"
    --profile-path /nix/var/nix/profiles/system
    --temp-path "$temp_path"
    --confirm-timeout "$(jq -r '.activation.confirmTimeout' "$CONFIG")"
  )
  [ "$magic_rollback" = true ] && args+=(--magic-rollback)
  [ "$(jq -r '.activation.autoRollback' "$CONFIG")" = true ] && args+=(--auto-rollback)

  if [ "$magic_rollback" != true ]; then
    run_activation "$activatable/activate-rs" "${args[@]}"
    return
  fi

  wait_log=$CLIENT_DIR/activate-rs-wait.log
  : >"$wait_log"

  run_activation "$activatable/activate-rs" "${args[@]}" &
  activate_pid=$!
  if ! run_activation "$activatable/activate-rs" wait "$activatable" --temp-path "$temp_path" --activation-timeout "$activation_timeout" >"$wait_log" 2>&1; then
    wait "$activate_pid" || true
    printf 'nixpull: activate-rs wait failed; see %s\n' "$wait_log" >&2
    return 1
  fi

  store_name=${activatable#/nix/store/}
  store_hash=${store_name%%-*}
  canary=$temp_path/deploy-rs-canary-$store_hash
  rm -f "$canary"
  wait "$activate_pid"
}

cmd_activate() {
  ensure_client_state

  local host metadata result
  host=$(hostname_short)
  metadata=$(jq -e '.fetched' "$CLIENT_STATE") || {
    printf 'nixpull: no fetched profile to activate\n' >&2
    return 1
  }

  print_nixpull_event "activating" "$(jq -r '.activatablePath' <<<"$metadata")"
  if activate_latest "$metadata"; then
    result=$(jq -n \
      --arg status success \
      --arg at "$(date --iso-8601=seconds)" \
      --arg activatablePath "$(jq -r '.activatablePath' <<<"$metadata")" \
      --arg toplevelPath "$(jq -r '.toplevelPath' <<<"$metadata")" \
      '{status: $status, at: $at, activatablePath: $activatablePath, toplevelPath: $toplevelPath}')
    jq --argjson result "$result" '.lastPull = $result' "$CLIENT_STATE" | atomic_write "$CLIENT_STATE"
    log_line "$CLIENT_LOG" "pull success host=$host activatablePath=$(jq -r '.activatablePath' <<<"$metadata")"
    print_nixpull_event "activated" "$(jq -r '.activatablePath' <<<"$metadata")"
  else
    local rc=$?
    result=$(jq -n \
      --arg status failure \
      --arg at "$(date --iso-8601=seconds)" \
      --argjson exitCode "$rc" \
      --arg activatablePath "$(jq -r '.activatablePath' <<<"$metadata")" \
      --arg toplevelPath "$(jq -r '.toplevelPath' <<<"$metadata")" \
      '{status: $status, at: $at, exitCode: $exitCode, activatablePath: $activatablePath, toplevelPath: $toplevelPath}')
    jq --argjson result "$result" '.lastPull = $result' "$CLIENT_STATE" | atomic_write "$CLIENT_STATE"
    log_line "$CLIENT_LOG" "pull failure host=$host rc=$rc activatablePath=$(jq -r '.activatablePath' <<<"$metadata")"
    return "$rc"
  fi
}

cmd_pull() {
  ensure_client_state
  local ask=0
  case "${1:-}" in
    -a|--ask) ask=1 ;;
    "") ;;
    *) usage; exit 2 ;;
  esac

  local host metadata toplevel
  host=$(hostname_short)
  if metadata=$(fetch_metadata "$host"); then
    :
  else
    local rc=$?
    log_line "$CLIENT_LOG" "pull failed fetch rc=$rc"
    return "$rc"
  fi
  if fetch_closure "$host" "$metadata" >/dev/null; then
    :
  else
    local rc=$?
    log_line "$CLIENT_LOG" "pull failed fetch rc=$rc"
    return "$rc"
  fi
  toplevel=$(jq -r '.toplevelPath' <<<"$metadata")
  if [ "$ask" -eq 1 ]; then
    if command -v dix >/dev/null 2>&1; then
      dix /run/current-system "$toplevel" || printf 'warning: dix failed; continuing to confirmation\n' >&2
    else
      printf 'warning: dix is not installed; skipping diff\n' >&2
    fi
    if ! confirm_activation "$(jq -r '.activatablePath' <<<"$metadata")"; then
      log_line "$CLIENT_LOG" "pull declined host=$host activatablePath=$(jq -r '.activatablePath' <<<"$metadata")"
      print_nixpull_event "activation skipped" "fetched closure remains in the store"
      return 0
    fi
  fi

  cmd_activate
}

cmd_status() {
  local host published fetched last_pull published_hosts last_build
  host=$(hostname_short)
  printf 'host: %s\n' "$host"
  printf 'current: %s\n' "$(current_system)"
  if [ -f "$CLIENT_STATE" ]; then
    fetched=$(jq -r '.fetched.activatablePath // "none"' "$CLIENT_STATE")
    last_pull=$(jq -c '.lastPull // "none"' "$CLIENT_STATE")
    printf 'fetched: %s\n' "$fetched"
    printf 'lastPull: %s\n' "$last_pull"
  fi
  if published=$(fetch_metadata "$host" 2>/dev/null); then
    printf 'published: %s\n' "$(jq -r '.activatablePath' <<<"$published")"
    printf 'publishedBuiltAt: %s\n' "$(jq -r '.builtAt' <<<"$published")"
  elif [ -f "$BUILDER_STATE" ]; then
    published_hosts=$(jq -r '.published | keys | join(",")' "$BUILDER_STATE")
    last_build=$(jq -c '.lastBuild' "$BUILDER_STATE")
    printf 'published hosts: %s\n' "$published_hosts"
    printf 'lastBuild: %s\n' "$last_build"
  else
    printf 'published: unavailable\n'
  fi
}

cmd_check() {
  local host metadata current fetched
  host=$(hostname_short)
  metadata=$(fetch_metadata "$host")
  current=$(current_system)
  fetched=$(jq -r '.fetched.activatablePath // empty' "$CLIENT_STATE" 2>/dev/null || true)
  printf 'published: %s\n' "$(jq -r '.activatablePath' <<<"$metadata")"
  printf 'fetched: %s\n' "${fetched:-none}"
  printf 'current: %s\n' "${current:-unknown}"
}

shorten_output_path() {
  local value=$1 max=86 keep_start=34 keep_end=46
  if [ "${#value}" -le "$max" ]; then
    printf '%s\n' "$value"
  else
    printf '%s...%s\n' "${value:0:keep_start}" "${value: -keep_end}"
  fi
}

gum_output_available() {
  command -v gum >/dev/null 2>&1 && [ -t 1 ]
}

print_nixpull_event() {
  local message=$1 detail=${2:-}
  if gum_output_available; then
    gum style --foreground 39 --bold "nixpull: $message"
    if [ -n "$detail" ]; then
      gum style --foreground 245 "  $(shorten_output_path "$detail")"
    fi
  else
    if [ -n "$detail" ]; then
      printf '%s %s\n' "$message" "$detail"
    else
      printf '%s\n' "$message"
    fi
  fi
}

print_build_host() {
  local host=$1
  if gum_output_available; then
    gum style --foreground 39 --bold "$host"
  else
    printf '%s\n' "$host"
  fi
}

print_build_start() {
  local host_count=$1 max_jobs=$2
  if gum_output_available; then
    gum style --foreground 39 --bold "nixpull build: $host_count hosts (maxJobs=$max_jobs)"
  else
    printf 'nixpull build: %s hosts (maxJobs=%s)\n' "$host_count" "$max_jobs"
  fi
}

print_build_published() {
  local host=$1
  if gum_output_available; then
    gum style --foreground 245 "  published $host"
  else
    printf '  published %s\n' "$host"
  fi
}

print_build_failed() {
  local host=$1
  if gum_output_available; then
    gum style --foreground 9 "  failed $host"
  else
    printf '  failed %s\n' "$host"
  fi
}

nom_build_store_paths() {
  local log=$1 activatable_attr=$2 toplevel_attr=$3 output line tmp rc
  shift 3
  tmp=$(mktemp)
  if nom build "$activatable_attr" "$toplevel_attr" --print-out-paths --no-link "$@" > >(tee "$tmp" | tee -a "$log" >&2) 2> >(tee -a "$log" >&2); then
    rc=0
  else
    rc=$?
  fi
  output=$(<"$tmp")
  rm -f "$tmp"
  [ "$rc" -eq 0 ] || return "$rc"

  while IFS= read -r line; do
    case "$line" in
      /nix/store/*) printf '%s\n' "$line" ;;
    esac
  done <<<"$output"
}

confirm_activation() {
  local activatable=$1 answer
  printf 'Activate %s? [y/N] ' "$(shorten_output_path "$activatable")"
  read -r answer
  case "$answer" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

case "${1:-}" in
  build) shift; cmd_build "$@" ;;
  fetch) shift; cmd_fetch "$@" ;;
  pull) shift; cmd_pull "$@" ;;
  activate) shift; cmd_activate "$@" ;;
  status) shift; cmd_status "$@" ;;
  check) shift; cmd_check "$@" ;;
  -h|--help|help) usage ;;
  *) usage; exit 2 ;;
esac
