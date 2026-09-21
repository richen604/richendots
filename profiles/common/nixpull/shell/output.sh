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

nom_output_available() {
  command -v nom >/dev/null 2>&1 && [ -t 2 ]
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

confirm_activation() {
  local activatable=$1 answer
  printf 'Activate %s? [y/N] ' "$(shorten_output_path "$activatable")"
  read -r answer
  case "$answer" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}
