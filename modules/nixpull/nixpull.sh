# nixpull - pull-based nixos config updates
#
# enables a pull-based nixos updates across multiple hosts.
# the server builds all configurations and stores their paths, while hosts pull and apply them via ssh.
# supports interactive diffs and confirmation before switching.
#
# very much tailored to my usecase, you have been warned :)
#
# notes:
# - requires passwordless ssh access to the server
# - requires signed store paths or --no-check-sigs for nix copy

# shellcheck shell=bash
set -euo pipefail

SERVER="cedar.build"
CACHE_URL="http://10.0.0.155:5000"
STORE_DIR="/tmp/nixpull"
STATE_DIR="/tmp/nixpull/state"

COLOR_PRIMARY="75"
COLOR_SUCCESS="36"
COLOR_ERROR="203"
COLOR_WARNING="215"
COLOR_MUTED="245"
COLOR_ACCENT="141"
export GUM_SPIN_SPINNER_FOREGROUND="$COLOR_ACCENT"
export GUM_CONFIRM_PROMPT_FOREGROUND="$COLOR_PRIMARY"
export GUM_CONFIRM_SELECTED_BACKGROUND="$COLOR_ACCENT"

usage() {
  local banner usage_label commands_label build_cmd pull_cmd pull_a_cmd check_cmd
  banner=$(gum style \
    --foreground "$COLOR_PRIMARY" --border-foreground "$COLOR_MUTED" --border rounded \
    --width 50 --padding "0 1" \
    "nixpull" "pull-based nixos updates")
  usage_label=$(gum style --bold --foreground "$COLOR_PRIMARY" "usage:")
  commands_label=$(gum style --bold --foreground "$COLOR_PRIMARY" "commands:")
  build_cmd=$(gum style --foreground "$COLOR_ACCENT" "build   ")
  pull_cmd=$(gum style --foreground "$COLOR_ACCENT" "pull    ")
  pull_a_cmd=$(gum style --foreground "$COLOR_ACCENT" "pull -a ")
  check_cmd=$(gum style --foreground "$COLOR_ACCENT" "check   ")
  
  cat << EOF
$banner

$usage_label nixpull <build|pull|check>

$commands_label
  $build_cmd - build all nixconfigurations and store paths (run on server)
  $pull_cmd - fetch and apply system configuration from server (run on host)
  $pull_a_cmd - fetch and ask before applying (shows dix diff)
  $check_cmd - check if new build is available (run on host)
EOF
  exit 1
}

build() {
  LOCK_FILE="/tmp/nixpull.lock"
  if [ -f "$LOCK_FILE" ]; then
    gum style --foreground "$COLOR_ERROR" --bold "✗ build already in progress (lock file exists)" >&2
    exit 1
  fi
  trap 'rm -f "$LOCK_FILE"' EXIT
  touch "$LOCK_FILE"

  gum style --foreground "$COLOR_PRIMARY" --bold "building all nixos configurations..." >&2
  
  mkdir -p "$STORE_DIR"
  
  configs=$(gum spin --spinner dot --title "discovering configurations..." -- \
    sh -c 'nix flake show --json 2>/dev/null | jq -r ".nixosConfigurations | keys[]"')
  
  if [ -z "$configs" ]; then
    gum style --foreground "$COLOR_ERROR" --bold "✗ no nixosconfigurations found in flake" >&2
    exit 1
  fi
  
  declare -A store_paths
  
  for config in $configs; do
    if ! store_path=$(gum spin --spinner dot --title "building $config..." -- \
      sh -c "nix build '.#nixosConfigurations.$config.config.system.build.toplevel' --refresh --print-out-paths --no-link 2>&1 | tail -n1"); then
      gum style --foreground "$COLOR_ERROR" --bold "✗ failed to build $config" >&2
      exit 1
    fi
    
    store_paths[$config]=$store_path
    echo "$(gum style --foreground "$COLOR_ACCENT" "  ✓ $config") $(gum style --foreground "$COLOR_MUTED" "→ $store_path")" >&2
  done
  
  for config in "${!store_paths[@]}"; do
    echo "${store_paths[$config]}" > "$STORE_DIR/$config.txt"
  done
  date +%s > "$STORE_DIR/timestamp"
  
  gum style --foreground "$COLOR_SUCCESS" --bold "✓ build complete. store paths saved to $STORE_DIR/" >&2
}

check() {
  hostname=$(hostname)
  mkdir -p "$STATE_DIR"
  
  store_path=$(gum spin --spinner dot --title "checking for updates on $SERVER..." -- \
    ssh "$SERVER" "cat $STORE_DIR/$hostname.txt" 2>/dev/null || echo "")
  
  if [ -z "$store_path" ]; then
    gum style --foreground "$COLOR_ERROR" "✗ no build available on server for $hostname"
    exit 1
  fi
  
  current_path=$(readlink /run/current-system 2>/dev/null || echo "")
  
  if [ "$store_path" != "$current_path" ]; then
    gum style --foreground "$COLOR_SUCCESS" --bold "✓ new build available"
    gum style --foreground "$COLOR_MUTED" "  $store_path"
    exit 0
  else
    gum style --foreground "$COLOR_MUTED" "already on latest: $current_path"
    exit 1
  fi
}

pull() {
  local ask_before_switch=0
  
  if [ "${1:-}" = "-a" ] || [ "${1:-}" = "--ask" ]; then
    ask_before_switch=1
  fi
  
  hostname=$(hostname)
  mkdir -p "$STATE_DIR"
  

  store_path=$(gum spin --spinner dot --title "fetching configuration for $hostname..." -- \
    ssh "$SERVER" "cat $STORE_DIR/$hostname.txt" 2>/dev/null || echo "")
  
  if [ -z "$store_path" ]; then
    gum style --foreground "$COLOR_ERROR" --bold "✗ no configuration found for $hostname"
    gum style --foreground "$COLOR_MUTED" "  run 'nixpull build' on $SERVER first"
    exit 1
  fi
  
  current_path=$(readlink /run/current-system 2>/dev/null || echo "")
  
  if [ "$current_path" = "$store_path" ]; then
    gum style --foreground "$COLOR_SUCCESS" --bold "✓ already on latest version"
    exit 0
  fi
  
  # youll need to add --no-check-sigs if you don't have signatures setup
  gum spin --spinner dot --title "copying closure from cache..." -- \
    sh -c "nix copy --from '$CACHE_URL' '$store_path' 2>&1 | grep -v '^copying path' | grep -v '^$' || true"
  
  if [ -n "$current_path" ] && command -v dix >/dev/null 2>&1; then
    gum style --foreground "$COLOR_PRIMARY" --bold "changes:"
    dix "$current_path" "$store_path" || \
      gum style --foreground "$COLOR_WARNING" "  ⚠ diff unavailable"
  fi
  
  if [ $ask_before_switch -eq 1 ]; then
    if ! gum confirm "apply this update?"; then
      gum style --foreground "$COLOR_MUTED" "cancelled"
      exit 0
    fi
  fi
  
  sudo -v
  gum spin --spinner dot --title "activating..." --show-output -- \
    sh -c "sudo '$store_path/bin/switch-to-configuration' switch 2>&1 | grep -E '(error|warning|failed)' || true"
  
  echo "$store_path" > "$STATE_DIR/current"
  
  gum style --foreground "$COLOR_SUCCESS" --bold "✓ system updated"
}

case "${1:-}" in
  build) build ;;
  pull)  shift; pull "$@" ;;
  check) check ;;
  *)     usage ;;
esac
