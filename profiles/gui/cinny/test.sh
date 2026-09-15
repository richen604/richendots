#!/usr/bin/env bash
set -euo pipefail

profile_dir=$(cd "$(dirname "$0")" && pwd)
tmp=$(mktemp -d)
server_pid=
trap 'test -z "$server_pid" || kill "$server_pid" 2>/dev/null || true; chmod -R u+w "$tmp" 2>/dev/null || true; rm -rf "$tmp"' EXIT

web_root="$tmp/web root"
mkdir -p "$web_root"
printf '%s\n' '<!doctype html><title>Cinny fallback marker</title>' >"$web_root/index.html"
printf '%s\n' '{"source":"immutable"}' >"$web_root/config.json"
chmod -R a-w "$web_root"
cinny_data_home="$tmp/cinny data"
port=18432
XDG_DATA_HOME="$cinny_data_home" STATIC_WEB_SERVER=${STATIC_WEB_SERVER:-static-web-server} \
  bash "$profile_dir/serve.sh" "$web_root" "$port" &
server_pid=$!
for _ in $(seq 1 30); do
  if curl --fail --silent "http://127.0.0.1:$port/login/matrix.org?loginToken=test" >"$tmp/callback"; then
    break
  fi
  sleep 0.1
done
grep -qF 'Cinny fallback marker' "$tmp/callback"
curl --fail --silent "http://127.0.0.1:$port/config.json" >"$tmp/served-config"
cmp "$web_root/config.json" "$tmp/served-config"
kill "$server_pid"
wait "$server_pid" 2>/dev/null || true
server_pid=

mkdir -p "$cinny_data_home/cinny"
printf '%s\n' '{"source":"runtime override"}' >"$cinny_data_home/cinny/config.json"
XDG_DATA_HOME="$cinny_data_home" STATIC_WEB_SERVER=${STATIC_WEB_SERVER:-static-web-server} \
  bash "$profile_dir/serve.sh" "$web_root" "$port" &
server_pid=$!
for _ in $(seq 1 30); do
  if curl --fail --silent "http://127.0.0.1:$port/config.json" >"$tmp/served-config"; then
    break
  fi
  sleep 0.1
done
cmp "$cinny_data_home/cinny/config.json" "$tmp/served-config"
kill "$server_pid"
wait "$server_pid" 2>/dev/null || true
server_pid=

data_home="$tmp/data home"
config="$data_home/firefoxpwa/config.json"
calls="$tmp/calls"
manifest=http://127.0.0.1:16432/manifest.webmanifest
document=http://127.0.0.1:16432/

cat >"$tmp/firefoxpwa" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"$CALLS"
if [[ $1 == site && $2 == list ]]; then
  if [[ ! -e $CONFIG ]]; then
    mkdir -p "$(dirname "$CONFIG")"
    printf '%s\n' '{"profiles":{"00000000000000000000000000":{"sites":[]}},"sites":{}}' >"$CONFIG"
  fi
  exit 0
fi
if [[ $1 != site || $2 != install ]]; then
  exit 0
fi
jq --arg manifest "$3" --arg document "$5" \
  '.sites.TESTSITE={config:{manifest_url:$manifest,document_url:$document}}' \
  "$CONFIG" >"$CONFIG.tmp"
mv "$CONFIG.tmp" "$CONFIG"
EOF
cat >"$tmp/curl" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$tmp/firefoxpwa" "$tmp/curl"

export CALLS="$calls" CONFIG="$config" XDG_DATA_HOME="$data_home" FIREFOXPWA="$tmp/firefoxpwa" CURL="$tmp/curl"
unset CINNY_PWA_CONFIG
first=$(bash "$profile_dir/ensure-pwa.sh" "$manifest" "$document")
second=$(bash "$profile_dir/ensure-pwa.sh" "$manifest" "$document")

test "$first" = TESTSITE
test "$second" = TESTSITE
cat >"$tmp/expected-bootstrap" <<EOF
site list
site install $manifest --document-url $document --name Cinny
EOF
cmp "$tmp/expected-bootstrap" "$calls"

jq \
  '.sites.TESTSITE.config.document_url="http://127.0.0.1:9999/"' \
  "$config" >"$config.tmp"
mv "$config.tmp" "$config"
if bash "$profile_dir/ensure-pwa.sh" "$manifest" "$document" 2>"$tmp/stale-error"; then
  echo "stale registration unexpectedly accepted" >&2
  exit 1
fi
grep -qF "Cinny PWA registration has wrong document URL" "$tmp/stale-error"
jq --arg document "$document" '.sites.TESTSITE.config.document_url=$document' "$config" >"$config.tmp"
mv "$config.tmp" "$config"

cat >"$tmp/wlrctl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'wlrctl %s\n' "$*" >>"$CALLS"
if [[ $1 == toplevel && $2 == find ]]; then
  exit "${WINDOW_MISSING:-0}"
fi
EOF
chmod +x "$tmp/wlrctl"

: >"$calls"
export WLRCTL="$tmp/wlrctl" WINDOW_MISSING=0
bash "$profile_dir/tray-action.sh" show "$manifest"
bash "$profile_dir/tray-action.sh" hide "$manifest"
bash "$profile_dir/tray-action.sh" quit "$manifest"

cat >"$tmp/expected" <<'EOF'
wlrctl toplevel find app_id:FFPWA-TESTSITE
wlrctl toplevel focus app_id:FFPWA-TESTSITE
wlrctl toplevel minimize app_id:FFPWA-TESTSITE
wlrctl toplevel close app_id:FFPWA-TESTSITE
EOF
cmp "$tmp/expected" "$calls"

: >"$calls"
export WINDOW_MISSING=1
bash "$profile_dir/tray-action.sh" show "$manifest"
test "$(tail -n 1 "$calls")" = "site launch TESTSITE"

cat >"$tmp/systrayhelper" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' '{"type":"ready"}'
IFS= read -r menu
printf '%s\n' "$menu" >"$TRAY_MENU"
printf '%s\n' 'not-json'
printf '%s\n' '{"type":"ready"}'
printf '%s\n' '{"type":"clicked","item":{"title":"Unknown"},"seq_id":9}'
printf '%s\n' '{"type":"clicked","item":{"title":"Show"},"seq_id":0}'
printf '%s\n' '{"type":"clicked","item":{"title":"Hide"},"seq_id":1}'
printf '%s\n' '{"type":"clicked","item":{"title":"Quit"},"seq_id":2}'
printf '%s\n' '{"type":"clicked","item":{"title":"Show"},"seq_id":0}'
EOF
cat >"$tmp/tray-dispatch" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$1" >>"$TRAY_CALLS"
EOF
chmod +x "$tmp/systrayhelper" "$tmp/tray-dispatch"
printf 'fake-png' >"$tmp/icon.png"
export SYSTRAYHELPER="$tmp/systrayhelper"
export CINNY_TRAY_DISPATCH="$tmp/tray-dispatch"
export CINNY_TRAY_ICON="$tmp/icon.png"
export TRAY_MENU="$tmp/tray-menu" TRAY_CALLS="$tmp/tray-calls"
bash "$profile_dir/systray.sh"

jq -e '
  .title == "Cinny" and
  .tooltip == "Cinny" and
  (.icon | length > 0) and
  ([.items[].title] == ["Show", "Hide", "Quit"]) and
  all(.items[]; .enabled == true)
' "$TRAY_MENU" >/dev/null
printf '%s\n' show hide quit show >"$tmp/expected-tray-calls"
cmp "$tmp/expected-tray-calls" "$TRAY_CALLS"
