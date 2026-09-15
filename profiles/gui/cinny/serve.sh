set -eu

root=$1
port=$2
server=${STATIC_WEB_SERVER:-static-web-server}
data_home=${XDG_DATA_HOME:-$HOME/.local/share}
override_config=$data_home/cinny/config.json
runtime_root=$(mktemp -d "${XDG_RUNTIME_DIR:-/tmp}/cinny-web.XXXXXX")

cleanup() {
  rm -rf -- "$runtime_root"
}
trap cleanup EXIT INT TERM

cp -r --reflink=auto -- "$root"/. "$runtime_root"/
chmod -R u+w "$runtime_root"
if [ -f "$override_config" ]; then
  cp -- "$override_config" "$runtime_root/config.json"
fi

"$server" \
  --host 127.0.0.1 \
  --port "$port" \
  --root "$runtime_root" \
  --page-fallback "$runtime_root/index.html" &
server_pid=$!
trap 'kill "$server_pid" 2>/dev/null || true; cleanup' EXIT INT TERM
wait "$server_pid"
