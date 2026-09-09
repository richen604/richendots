set -eu

manifest_url=$1
document_url=$2
config=${CINNY_PWA_CONFIG:-"${XDG_DATA_HOME:-$HOME/.local/share}/firefoxpwa/config.json"}
firefoxpwa=${FIREFOXPWA:-firefoxpwa}
curl=${CURL:-curl}

attempt=0
until "$curl" --fail --silent --show-error "$manifest_url" >/dev/null; do
  attempt=$((attempt + 1))
  if [ "$attempt" -ge 30 ]; then
    echo "Cinny web server did not become ready" >&2
    exit 1
  fi
  sleep 1
done

if [ ! -e "$config" ]; then
  "$firefoxpwa" site list >/dev/null
fi
if [ ! -e "$config" ]; then
  echo "FirefoxPWA did not initialize its configuration" >&2
  exit 1
fi

site_id=$(
  jq -r --arg manifest "$manifest_url" --arg document "$document_url" \
    '.sites | to_entries[] | select(.value.config.manifest_url == $manifest and .value.config.document_url == $document) | .key' \
    "$config" 2>/dev/null | head -n 1
)

if [ -z "$site_id" ]; then
  stale_site_id=$(
    jq -r --arg manifest "$manifest_url" \
      '.sites | to_entries[] | select(.value.config.manifest_url == $manifest) | .key' \
      "$config" 2>/dev/null | head -n 1
  )
  if [ -n "$stale_site_id" ]; then
    echo "Cinny PWA registration has wrong document URL; uninstall site $stale_site_id and restart the session" >&2
    exit 1
  fi

  "$firefoxpwa" site install "$manifest_url" \
    --document-url "$document_url" \
    --name Cinny
  site_id=$(
    jq -r --arg manifest "$manifest_url" --arg document "$document_url" \
      '.sites | to_entries[] | select(.value.config.manifest_url == $manifest and .value.config.document_url == $document) | .key' \
      "$config" | head -n 1
  )
fi

if [ -z "$site_id" ]; then
  echo "FirefoxPWA did not register Cinny" >&2
  exit 1
fi

printf '%s\n' "$site_id"
