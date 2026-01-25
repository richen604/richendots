{ pkgs, ... }:

pkgs.writeShellScriptBin "spotify-spicetified" ''
  #!/usr/bin/env sh
  set -e

  APP_ID="com.spotify.Client"
  SPOTIFY_PATH="$HOME/.var/app/$APP_ID"
  SPICETIFY_DIR="$HOME/.config/spicetify"
  PREFS="$SPOTIFY_PATH/config/spotify/prefs"
  TIMEOUT=30

  echo "==> Checking Flathub repository..."
  flatpak remote-add --user --if-not-exists flathub \
    https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

  echo "==> Checking Spotify installation..."
  if ! flatpak info --user "$APP_ID" >/dev/null 2>&1; then
    echo "==> Installing Spotify from Flathub..."
    flatpak install --user -y flathub "$APP_ID"

    echo "==> Initializing Spotify to create config files..."
    flatpak run --user "$APP_ID"

    echo "==> Waiting for preferences file ($PREFS)..."
    ELAPSED=0
    while [ ! -f "$PREFS" ] && [ $ELAPSED -lt $TIMEOUT ]; do
      sleep 1
      ELAPSED=$((ELAPSED + 1))
    done


    echo "==> Configuring Spicetify..."
    spicetify config prefs_path "$PREFS"

    echo "==> Creating backup and applying Spicetify..."
    spicetify backup || true

    sleep 2

    echo "==> Installing Spicetify Marketplace..."
    # download uri
    releases_uri=https://github.com/spicetify/marketplace/releases
    if [ $# -gt 0 ]; then
      tag=$1
    else
      tag=$(curl -LsH 'Accept: application/json' $releases_uri/latest)
      tag=''${tag%\,\"update_url*}
      tag=''${tag##*tag_name\":\"}
      tag=''${tag%\"}
    fi

    tag=''${tag#v}

    echo "FETCHING Version $tag"

    download_uri=$releases_uri/download/v$tag/marketplace.zip
    default_color_uri="https://raw.githubusercontent.com/spicetify/marketplace/main/resources/color.ini"

    SPICETIFY_CONFIG_DIR="$SPICETIFY_CONFIG"
    if [ -z "$SPICETIFY_CONFIG_DIR" ]; then
      SPICETIFY_CONFIG_DIR="''${XDG_CONFIG_HOME:-$HOME/.config}/spicetify"
    fi
    INSTALL_DIR="$SPICETIFY_CONFIG_DIR/CustomApps"

    if [ ! -d "$INSTALL_DIR" ]; then
        echo "MAKING FOLDER  $INSTALL_DIR";
        mkdir -p "$INSTALL_DIR"
    fi

    TAR_FILE="$INSTALL_DIR/marketplace-dist.zip"

    echo "DOWNLOADING $download_uri"
    curl --fail --location --progress-bar --output "$TAR_FILE" "$download_uri"
    cd "$INSTALL_DIR"

    echo "EXTRACTING"
    unzip -q -d "$INSTALL_DIR/marketplace-tmp" -o "$TAR_FILE"

    cd "$INSTALL_DIR/marketplace-tmp"
    echo "COPYING"
    rm -rf "$INSTALL_DIR/marketplace/"
    mv "$INSTALL_DIR/marketplace-tmp/marketplace-dist" "$INSTALL_DIR/marketplace"

    echo "INSTALLING"
    cd "$INSTALL_DIR/marketplace"

    # Remove old custom app name if exists
    spicetify config custom_apps marketplace

    # Color injection fix
    spicetify config inject_css 1
    spicetify config replace_colors 1

    current_theme=$(spicetify config current_theme)
    if [ ''${#current_theme} -le 3 ]; then
        echo "No theme selected, using placeholder theme"
        if [ ! -d "$SPICETIFY_CONFIG_DIR/Themes/marketplace" ]; then
            echo "MAKING FOLDER  $SPICETIFY_CONFIG_DIR/Themes/marketplace";
            mkdir -p "$SPICETIFY_CONFIG_DIR/Themes/marketplace"
        fi
        curl --fail --location --progress-bar --output "$SPICETIFY_CONFIG_DIR/Themes/marketplace/color.ini" "$default_color_uri"
        spicetify config current_theme marketplace;
    fi

    echo "CLEANING UP"
    rm -rf "$TAR_FILE" "$INSTALL_DIR/marketplace-tmp/"

    echo "==> Applying Spictify TUI theme..."
    theme_url="https://raw.githubusercontent.com/AvinashReddy3108/spicetify-tui/master/tui"

    # Setup directories to download to
    spice_dir="$(dirname "$(spicetify -c)")"
    theme_dir="''${spice_dir}/Themes"

    # Make directories if needed
    mkdir -p "''${theme_dir}/tui"

    # Download latest tagged files into correct directory
    echo "Downloading spicetify-tui theme..."
    curl --silent --output "''${theme_dir}/tui/color.ini" "''${theme_url}/color.ini"
    curl --silent --output "''${theme_dir}/tui/user.css" "''${theme_url}/user.css"
    echo "Done"

    echo "Applying theme..."
    spicetify config current_theme tui color_scheme CatppuccinMocha
    
    echo "Applying patches..."
    # Insert patches after existing [Patch] header since CLI doesn't support them
    CONFIG_FILE="$(spicetify -c)"
    sed -i '/\[Patch\]/a xpui.js_find_8008 = ,(\\w+=)56,\nxpui.js_repl_8008 = ,''${1}32', "$CONFIG_FILE"
    
    sleep 2

    echo "==> Applying Spicetify themes and extensions..."
    spicetify apply

    echo "==> Setup complete!"
    exit 0
  fi

  echo "==> Launching Spotify..."
  exec flatpak run --user "$APP_ID"
''
