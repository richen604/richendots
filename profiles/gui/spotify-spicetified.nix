{
  pkgs,
  lib,
  richenLib,
  ...
}:

let
  spicetifyManaged = import ./hjem/config/spicetify/_managed.nix {
    inherit pkgs;
    inherit (richenLib) theme;
  };
  spotify-spicetified = pkgs.writeShellScriptBin "spotify-spicetified" ''
    set -e

    APP_ID="com.spotify.Client"
    state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/richendots/spicetify"
    stamp_file="$state_dir/applied-revision"
    backup_metadata="$state_dir/backup.ini"
    config_file="''${XDG_CONFIG_HOME:-$HOME/.config}/spicetify/config-xpui.ini"

    ${pkgs.coreutils}/bin/mkdir -p "$state_dir"

    if [ -s "$backup_metadata" ]; then
      config_tmp="$(${pkgs.coreutils}/bin/mktemp "$state_dir/config.XXXXXX")"
      ${pkgs.gawk}/bin/awk '
        /^\[Backup\]$/ { skipping = 1; next }
        skipping && /^\[/ { skipping = 0 }
        !skipping { print }
      ' "$config_file" > "$config_tmp"
      ${pkgs.coreutils}/bin/printf '\n' >> "$config_tmp"
      ${pkgs.coreutils}/bin/cat "$backup_metadata" >> "$config_tmp"
      ${pkgs.coreutils}/bin/install -m 0644 "$config_tmp" "$config_file"
      ${pkgs.coreutils}/bin/rm -f "$config_tmp"
    fi

    echo "==> Checking Flathub repository..."
    ${pkgs.flatpak}/bin/flatpak remote-add --user --if-not-exists flathub \
      https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

    echo "==> Checking Spotify installation..."
    if ! ${pkgs.flatpak}/bin/flatpak info --user "$APP_ID" >/dev/null 2>&1; then
      echo "==> Installing Spotify from Flathub..."
      ${pkgs.flatpak}/bin/flatpak install --user -y flathub "$APP_ID"

      echo "==> Initializing Spotify to create config files..."
      ${pkgs.flatpak}/bin/flatpak run --user "$APP_ID"

      sleep 2
    fi

    spotify_revision="$(${pkgs.flatpak}/bin/flatpak info --user --show-commit "$APP_ID")"
    spicetify_version="$(${pkgs.spicetify-cli}/bin/spicetify --version 2>&1)"
    desired_revision="${spicetifyManaged.bundle}:$spotify_revision:$spicetify_version"
    applied_revision=""
    if [ -r "$stamp_file" ]; then
      IFS= read -r applied_revision < "$stamp_file"
    fi

    if [ "$applied_revision" != "$desired_revision" ]; then
      echo "==> Applying managed Spicetify theme..."
      if ! ${pkgs.spicetify-cli}/bin/spicetify apply; then
        echo "==> Restoring and refreshing Spotify backup before retrying..."
        if ! ${pkgs.spicetify-cli}/bin/spicetify restore backup apply; then
          ${pkgs.spicetify-cli}/bin/spicetify backup apply
        fi
      fi

      backup_tmp="$(${pkgs.coreutils}/bin/mktemp "$state_dir/backup.XXXXXX")"
      ${pkgs.gawk}/bin/awk '
        /^\[Backup\]$/ { found = 1 }
        found && /^\[/ && $0 != "[Backup]" { exit }
        found { print }
      ' "$config_file" > "$backup_tmp"
      if [ -s "$backup_tmp" ]; then
        ${pkgs.coreutils}/bin/mv "$backup_tmp" "$backup_metadata"
      else
        ${pkgs.coreutils}/bin/rm -f "$backup_tmp"
      fi

      ${pkgs.coreutils}/bin/printf '%s\n' "$desired_revision" > "$stamp_file"
    fi

    echo "==> Launching Spotify..."
    exec ${pkgs.flatpak}/bin/flatpak run --user "$APP_ID"
  '';
in
{
  environment.systemPackages = [
    pkgs.spicetify-cli
    spotify-spicetified
  ];

  services.flatpak.enable = true;

  systemd.user.services.spotify.serviceConfig.ExecStart =
    lib.mkForce "${spotify-spicetified}/bin/spotify-spicetified";
}
