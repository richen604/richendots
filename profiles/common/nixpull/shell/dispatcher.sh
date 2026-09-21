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
case "${1:-}" in
  build) shift; cmd_build "$@" ;;
  fetch) shift; cmd_fetch "$@" ;;
  pull) shift; cmd_pull "$@" ;;
  activate) shift; cmd_activate "$@" ;;
  status) shift; cmd_status "$@" ;;
  check) shift; cmd_check "$@" ;;
  deliver-webhook)
    shift
    [ "$#" -eq 1 ] || { usage; exit 2; }
    deliver_webhook "$1"
    ;;
  -h|--help|help) usage ;;
  *) usage; exit 2 ;;
esac
