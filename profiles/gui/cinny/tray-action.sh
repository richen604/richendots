set -eu

action=$1
manifest_url=$2
config=${CINNY_PWA_CONFIG:-"${XDG_DATA_HOME:-$HOME/.local/share}/firefoxpwa/config.json"}
firefoxpwa=${FIREFOXPWA:-firefoxpwa}
wlrctl=${WLRCTL:-wlrctl}

site_id=$(
  jq -r --arg manifest "$manifest_url" \
    '.sites | to_entries[] | select(.value.config.manifest_url == $manifest) | .key' \
    "$config" | head -n 1
)
test -n "$site_id"
match="app_id:FFPWA-$site_id"

case "$action" in
  show)
    if "$wlrctl" toplevel find "$match"; then
      "$wlrctl" toplevel focus "$match"
    else
      "$firefoxpwa" site launch "$site_id"
    fi
    ;;
  hide)
    "$wlrctl" toplevel minimize "$match"
    ;;
  quit)
    "$wlrctl" toplevel close "$match"
    ;;
  *)
    echo "Usage: cinny-tray-action {show|hide|quit}" >&2
    exit 2
    ;;
esac
