deliver_webhook() {
  local host=$1 token_file token retries timeout url attempt started duration_ms urls=()
  [ "$(jq -r '.build.fetchWebhook.enable' "$CONFIG")" = true ] || return 0

  mapfile -t urls < <(jq -r --arg host "$host" '.build.fetchWebhook.urls[$host][]? // empty' "$CONFIG")
  if [ "${#urls[@]}" -eq 0 ]; then
    log_line "$BUILDER_LOG" "webhook skipped host=$host reason=no-configured-url delivery=polling-fallback"
    return 0
  fi

  token_file=$(jq -r '.build.fetchWebhook.tokenFile // empty' "$CONFIG")
  if [ -r "$token_file" ]; then
    token=$(tr -d '\r\n' <"$token_file")
  else
    log_line "$BUILDER_LOG" "webhook skipped host=$host reason=missing-token-file tokenFile=$token_file"
    return 0
  fi

  retries=$(jq -r '.build.fetchWebhook.retries' "$CONFIG")
  timeout=$(jq -r '.build.fetchWebhook.attemptTimeoutSec' "$CONFIG")

  for url in "${urls[@]}"; do
    attempt=1
    while [ "$attempt" -le "$retries" ]; do
      started=$(date +%s%3N)
      if printf 'header = "Authorization: Bearer %s"\n' "$token" \
        | curl --config - --fail --silent --show-error --location \
          --proto '=https' --proto-redir '=https' \
          --max-time "$timeout" -X POST "$url" >/dev/null; then
        duration_ms=$(($(date +%s%3N) - started))
        log_line "$BUILDER_LOG" "webhook success host=$host url=$url attempt=$attempt durationMs=$duration_ms"
        return 0
      fi
      duration_ms=$(($(date +%s%3N) - started))
      log_line "$BUILDER_LOG" "webhook attempt-failure host=$host url=$url attempt=$attempt durationMs=$duration_ms"
      attempt=$((attempt + 1))
    done
  done

  log_line "$BUILDER_LOG" "webhook failure host=$host urls=${#urls[@]} delivery=polling-fallback"
  return 0
}

queue_webhook() {
  local host=$1 unit
  unit=$(systemd-escape --template=nixpull-webhook-delivery@.service "$host")
  if systemctl start --no-block "$unit"; then
    log_line "$BUILDER_LOG" "webhook queued host=$host unit=$unit"
  else
    log_line "$BUILDER_LOG" "webhook queue-failure host=$host unit=$unit delivery=polling-fallback"
  fi
}

build_all_hosts() {
  local flake=$1 cores=$2 max_jobs=$3 outdir=$4
  shift 4
  local hosts=("$@") log=$outdir/build.log tmp args=() rc output path host activatable toplevel signing_key generation
  local started duration_ms metrics=$outdir/build.metrics sign_started sign_duration_ms
  tmp=$(mktemp)

  for host in "${hosts[@]}"; do
    args+=("$flake#nixpullProfiles.$host")
    args+=("$flake#nixosConfigurations.$host.config.system.build.toplevel")
  done
  args+=(--print-out-paths --no-link --keep-going --max-jobs "$max_jobs")
  if [ "$cores" != "null" ]; then
    args+=(--cores "$cores")
  fi

  : >"$log"
  started=$(date +%s%3N)
  if nom_output_available; then
    args+=(--log-format internal-json -v)
    if env time -f 'elapsedSec=%e userSec=%U systemSec=%S maxRssKiB=%M' -o "$metrics" nix build "${args[@]}" > >(tee "$tmp" | tee -a "$log") 2> >(tee -a "$log" | nom --json >&2); then
      rc=0
    else
      rc=$?
    fi
  else
    if env time -f 'elapsedSec=%e userSec=%U systemSec=%S maxRssKiB=%M' -o "$metrics" nix build "${args[@]}" > >(tee "$tmp" | tee -a "$log") 2> >(tee -a "$log" >&2); then
      rc=0
    else
      rc=$?
    fi
  fi

  output=$(<"$tmp")
  rm -f "$tmp"
  duration_ms=$(($(date +%s%3N) - started))

  signing_key=$(jq -r '.build.signingKeyFile // empty' "$CONFIG")
  for host in "${hosts[@]}"; do
    activatable=""
    toplevel=""
    while IFS= read -r path; do
      case "$path" in
        /nix/store/*-activatable-nixos-system-"$host"-*) activatable=$path ;;
        /nix/store/*-nixos-system-"$host"-*) toplevel=$path ;;
      esac
    done <<<"$output"

    if [ -n "$activatable" ] && [ -n "$toplevel" ]; then
      if [ -n "$signing_key" ]; then
        if [ ! -r "$signing_key" ]; then
          printf 'nixpull: signing key is not readable: %s\n' "$signing_key" >&2
          return 1
        fi
        sign_started=$(date +%s%3N)
        nix store sign --key-file "$signing_key" --recursive "$activatable" "$toplevel"
        sign_duration_ms=$(($(date +%s%3N) - sign_started))
      else
        sign_duration_ms=0
      fi
      generation=$(date +%s)
      jq -n \
        --arg host "$host" \
        --arg generation "$generation" \
        --arg activatablePath "$activatable" \
        --arg toplevelPath "$toplevel" \
        --arg builtAt "$(date --iso-8601=seconds)" \
        --argjson buildDurationMs "$duration_ms" \
        --argjson signingDurationMs "$sign_duration_ms" \
        --slurpfile source "$outdir/source.json" \
        '{host: $host, generation: ($generation | tonumber), activatablePath: $activatablePath, toplevelPath: $toplevelPath, builtAt: $builtAt, metrics: {buildDurationMs: $buildDurationMs, signingDurationMs: $signingDurationMs}} + $source[0]' >"$outdir/$host.json"
      log_line "$BUILDER_LOG" "build metrics host=$host batchDurationMs=$duration_ms signingMs=$sign_duration_ms $(cat "$metrics" 2>/dev/null || true)"
    fi
  done

  return "$rc"
}

publish_host() {
  local host=$1 meta_file=$2 state meta activatable publish_started duration_ms
  meta=$(cat "$meta_file")
  activatable=$(jq -r '.activatablePath' <<<"$meta")
  publish_started=$(date +%s%3N)
  root_published_profile "$host" "$activatable"
  exec 8>"$BUILDER_DIR/state.lock"
  flock 8
  state=$(cat "$BUILDER_STATE")
  jq --arg host "$host" --argjson meta "$meta" '.published[$host] = $meta' <<<"$state" | atomic_write "$BUILDER_STATE"
  flock -u 8
  duration_ms=$(($(date +%s%3N) - publish_started))
  log_line "$BUILDER_LOG" "build success host=$host activatablePath=$activatable publishMs=$duration_ms"
  print_build_published "$host"
}

build_flake_ref() {
  case "$1" in
    /*) printf 'path:%s\n' "$1" ;;
    *) printf '%s\n' "$1" ;;
  esac
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

  if [ -n "$flake_override" ] && [ "$(id -u)" -ne 0 ]; then
    printf 'nixpull: build flake override must be run as root\n' >&2
    return 77
  fi

  if [ "$(id -u)" -ne 0 ]; then
    dispatch_remote_build || escalate_build
  fi

  ensure_builder_state

  local flake build_flake max_jobs cores workdir failures=0 successes=0 publish_partial failed=0
  flake=${flake_override:-$(jq -r '.flake' "$CONFIG")}
  build_flake=$(build_flake_ref "$flake")
  max_jobs=$(jq -r '.build.maxJobs' "$CONFIG")
  cores=$(jq -r '.build.cores' "$CONFIG")
  publish_partial=$(jq -r '.build.publishPartial' "$CONFIG")
  workdir=$(mktemp -d "$BUILDER_DIR/build.XXXXXX")
  NIXPULL_BUILD_WORKDIR=$workdir
  trap cleanup_build_workdir EXIT

  exec 9>"$BUILDER_DIR/build.lock"
  if ! flock -n 9; then
    printf 'nixpull: build already running\n' >&2
    return 75
  fi

  source_metadata "$flake" >"$workdir/source.json"
  mapfile -t hosts < <(jq -r '.build.hosts[]' "$CONFIG")
  print_build_start "${#hosts[@]}" "$max_jobs"
  log_line "$BUILDER_LOG" "build start hosts=${hosts[*]} maxJobs=$max_jobs"

  local host
  if ! build_all_hosts "$build_flake" "$cores" "$max_jobs" "$workdir" "${hosts[@]}"; then
    failed=1
  fi

  if [ "$publish_partial" != true ] && [ "$failed" -ne 0 ]; then
    log_line "$BUILDER_LOG" "build failed; publishPartial=false so no hosts published"
    printf 'one or more builds failed; no hosts published because publishPartial=false\n' >&2
    return 1
  fi

  for host in "${hosts[@]}"; do
    if [ -f "$workdir/$host.json" ]; then
      successes=$((successes + 1))
      publish_host "$host" "$workdir/$host.json"
      queue_webhook "$host"
    else
      failures=$((failures + 1))
      log_line "$BUILDER_LOG" "build failure host=$host log=$workdir/build.log"
      print_build_failed "$host" >&2
      printf 'nixpull: build log retained at %s/logs/build.log\n' "$BUILDER_DIR" >&2
    fi
  done

  exec 8>"$BUILDER_DIR/state.lock"
  flock 8
  jq \
      --arg builtAt "$(date --iso-8601=seconds)" \
      --argjson successes "$successes" \
      --argjson failures "$failures" \
      '.lastBuild = {builtAt: $builtAt, successes: $successes, failures: $failures}' \
      "$BUILDER_STATE" | atomic_write "$BUILDER_STATE"
  flock -u 8

  log_line "$BUILDER_LOG" "build complete successes=$successes failures=$failures"
  [ "$failures" -eq 0 ]
}

