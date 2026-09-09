set -eu

helper=${SYSTRAYHELPER:-systrayhelper}
dispatcher=${CINNY_TRAY_DISPATCH:-cinny-tray-dispatch}
icon=${CINNY_TRAY_ICON:-${1:?missing tray icon}}

coproc TRAY { "$helper"; }
tray_pid=$!
exec {tray_out}<&"${TRAY[0]}"
exec {tray_in}>&"${TRAY[1]}"
trap 'kill "$tray_pid" 2>/dev/null || true' EXIT

IFS= read -r ready <&"$tray_out"
printf '%s\n' "$ready" | jq -e '.type == "ready"' >/dev/null

jq -cn --rawfile icon <(base64 -w0 "$icon") '{
  icon: $icon,
  title: "Cinny",
  tooltip: "Cinny",
  items: [
    {title: "Show", tooltip: "Show Cinny", enabled: true},
    {title: "Hide", tooltip: "Hide Cinny", enabled: true},
    {title: "Quit", tooltip: "Quit Cinny", enabled: true}
  ]
}' >&"$tray_in"

while IFS= read -r event <&"$tray_out"; do
  action=$(printf '%s\n' "$event" | jq -er 'select(.type == "clicked") | .item.title' 2>/dev/null) || continue
  case "$action" in
    Show) "$dispatcher" show ;;
    Hide) "$dispatcher" hide ;;
    Quit) "$dispatcher" quit ;;
  esac
done
