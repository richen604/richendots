fetch_metadata() {
  local host=$1 remote_state metadata metadata_url started duration_ms
  metadata_url=$(jq -r '.server.metadataUrl' "$CONFIG")
  started=$(date +%s%3N)
  if ! remote_state=$(curl --fail --silent --show-error --location --connect-timeout 10 "$metadata_url"); then
    printf 'nixpull: metadata URL unreachable; skipping fetch: %s\n' "$metadata_url" >&2
    log_line "$CLIENT_LOG" "fetch skip server-unreachable"
    return 75
  fi
  duration_ms=$(($(date +%s%3N) - started))
  log_line "$CLIENT_LOG" "metadata success host=$host durationMs=$duration_ms bytes=${#remote_state}"
  metadata=$(jq -e --arg host "$host" '.published[$host]' <<<"$remote_state") || {
    printf 'nixpull: no published build for %s\n' "$host" >&2
    return 1
  }
  printf '%s\n' "$metadata"
}

fetch_closure() {
  local host=$1 metadata=$2 activatable substituter started duration_ms closure_bytes
  local -a closure_paths
  activatable=$(jq -r '.activatablePath' <<<"$metadata")
  if [ -x "$activatable/activate-rs" ] \
    && nix path-info --recursive "$activatable" >/dev/null 2>&1; then
    print_nixpull_event "already fetched" "$activatable"
    log_line "$CLIENT_LOG" "fetch noop host=$host activatablePath=$activatable"
  else
    substituter=$(jq -r '.server.substituterUrl' "$CONFIG")
    started=$(date +%s%3N)
    if [ -e "$activatable" ]; then
      mapfile -t closure_paths < <(nix path-info --refresh --store "$substituter" --recursive "$activatable")
      if [ "${#closure_paths[@]}" -eq 0 ]; then
        printf 'nixpull: substituter returned an empty closure: %s\n' "$substituter" >&2
        log_line "$CLIENT_LOG" "fetch failure empty-closure host=$host activatablePath=$activatable substituter=$substituter"
        return 1
      fi
      nix copy --refresh --from "$substituter" "${closure_paths[@]}"
      if ! nix path-info --recursive "$activatable" >/dev/null 2>&1; then
        printf 'nixpull: fetched closure is incomplete: %s\n' "$activatable" >&2
        log_line "$CLIENT_LOG" "fetch failure incomplete-closure host=$host activatablePath=$activatable"
        return 1
      fi
    else
      nix copy --refresh --from "$substituter" "$activatable"
    fi
    duration_ms=$(($(date +%s%3N) - started))
    if [ ! -x "$activatable/activate-rs" ]; then
      printf 'nixpull: fetched path is missing executable activate-rs: %s\n' "$activatable" >&2
      log_line "$CLIENT_LOG" "fetch failure missing-activate-rs host=$host activatablePath=$activatable"
      return 1
    fi
    closure_bytes=$(nix path-info --json --json-format 1 --closure-size "$activatable" 2>/dev/null | jq -r 'to_entries[0].value.closureSize // 0' 2>/dev/null || printf 0)
    log_line "$CLIENT_LOG" "fetch success host=$host activatablePath=$activatable durationMs=$duration_ms closureBytes=$closure_bytes"
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
  local metadata=$1 activatable temp_path activation_timeout magic_rollback activate_pid store_name store_hash canary cancel wait_log
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

  store_name=${activatable#/nix/store/}
  store_hash=${store_name%%-*}
  canary=$temp_path/deploy-rs-canary-$store_hash
  cancel=$temp_path/deploy-rs-cancel-$store_hash
  rm -f "$canary" "$cancel"

  wait_log=$CLIENT_DIR/activate-rs-wait.log
  : >"$wait_log"

  run_activation "$activatable/activate-rs" "${args[@]}" &
  activate_pid=$!
  if ! run_activation "$activatable/activate-rs" wait "$activatable" --temp-path "$temp_path" --activation-timeout "$activation_timeout" >"$wait_log" 2>&1; then
    wait "$activate_pid" || true
    printf 'nixpull: activate-rs wait failed; see %s\n' "$wait_log" >&2
    return 1
  fi

  rm -f "$canary"
  wait "$activate_pid"
}

record_activating() {
  local host=$1 metadata=$2 result
  result=$(jq -n \
    --arg status activating \
    --arg at "$(date --iso-8601=seconds)" \
    --arg activatablePath "$(jq -r '.activatablePath' <<<"$metadata")" \
    --arg toplevelPath "$(jq -r '.toplevelPath' <<<"$metadata")" \
    '{status: $status, at: $at, activatablePath: $activatablePath, toplevelPath: $toplevelPath}')
  jq --arg host "$host" --argjson result "$result" '.host = $host | .lastPull = $result' "$CLIENT_STATE" | atomic_write "$CLIENT_STATE"
}

cmd_activate() {
  ensure_client_state

  local host metadata result started duration_ms
  host=$(hostname_short)
  metadata=$(jq -e '.fetched' "$CLIENT_STATE") || {
    printf 'nixpull: no fetched profile to activate\n' >&2
    return 1
  }

  if [ "$(jq -r '.toplevelPath' <<<"$metadata")" = "$(readlink /run/current-system 2>/dev/null || true)" ]; then
    return 0
  fi

  record_activating "$host" "$metadata"
  print_nixpull_event "activating" "$(jq -r '.activatablePath' <<<"$metadata")"
  started=$(date +%s%3N)
  if activate_latest "$metadata"; then
    duration_ms=$(($(date +%s%3N) - started))
    result=$(jq -n \
      --arg status success \
      --arg at "$(date --iso-8601=seconds)" \
      --arg activatablePath "$(jq -r '.activatablePath' <<<"$metadata")" \
      --arg toplevelPath "$(jq -r '.toplevelPath' <<<"$metadata")" \
      '{status: $status, at: $at, activatablePath: $activatablePath, toplevelPath: $toplevelPath}')
    jq --argjson result "$result" '.lastPull = $result' "$CLIENT_STATE" | atomic_write "$CLIENT_STATE"
    log_line "$CLIENT_LOG" "pull success host=$host activatablePath=$(jq -r '.activatablePath' <<<"$metadata") activationMs=$duration_ms"
    print_nixpull_event "activated" "$(jq -r '.activatablePath' <<<"$metadata")"
  else
    local rc=$?
    duration_ms=$(($(date +%s%3N) - started))
    result=$(jq -n \
      --arg status failure \
      --arg at "$(date --iso-8601=seconds)" \
      --argjson exitCode "$rc" \
      --arg activatablePath "$(jq -r '.activatablePath' <<<"$metadata")" \
      --arg toplevelPath "$(jq -r '.toplevelPath' <<<"$metadata")" \
      '{status: $status, at: $at, exitCode: $exitCode, activatablePath: $activatablePath, toplevelPath: $toplevelPath}')
    jq --argjson result "$result" '.lastPull = $result' "$CLIENT_STATE" | atomic_write "$CLIENT_STATE"
    log_line "$CLIENT_LOG" "pull failure host=$host rc=$rc activatablePath=$(jq -r '.activatablePath' <<<"$metadata") activationMs=$duration_ms"
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
