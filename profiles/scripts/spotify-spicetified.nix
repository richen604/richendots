{ pkgs, ... }:

pkgs.writeShellScriptBin "spotify-spicetified" ''
  #!/usr/bin/env sh
  set -e

  APP_ID="com.spotify.Client"

  echo "==> Checking Flathub repository..."
  flatpak remote-add --user --if-not-exists flathub \
    https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

  echo "==> Checking Spotify installation..."
  if ! flatpak info --user "$APP_ID" >/dev/null 2>&1; then
    echo "==> Installing Spotify from Flathub..."
    flatpak install --user -y flathub "$APP_ID"

    echo "==> Initializing Spotify to create config files..."
    flatpak run --user "$APP_ID"

    sleep 2

    echo "==> Creating backup and applying Spicetify..."
    spicetify backup || true

    echo "==> Applying Spicetify themes and extensions..."
    spicetify apply

    echo "==> Setup complete!"
    exit 0
  fi

  echo "==> Launching Spotify..."
  exec flatpak run --user "$APP_ID"
''
