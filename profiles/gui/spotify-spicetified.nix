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
    set -eu

    APP_ID="com.spotify.Client"
    state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/richendots/spicetify"
    stamp_file="$state_dir/applied-revision"
    backup_metadata="$state_dir/backup.ini"
    config_file="''${XDG_CONFIG_HOME:-$HOME/.config}/spicetify/config-xpui.ini"

    ${pkgs.coreutils}/bin/mkdir -p "$state_dir"
    exec 9>"$state_dir/apply.lock"
    ${pkgs.util-linux}/bin/flock 9

    replace_backup_metadata() {
      source_file="$1"
      config_tmp="$(${pkgs.coreutils}/bin/mktemp "$state_dir/config.XXXXXX")"
      ${pkgs.gawk}/bin/awk '
        /^\[Backup\]$/ { skipping = 1; next }
        skipping && /^\[/ { skipping = 0 }
        !skipping { print }
      ' "$config_file" > "$config_tmp"
      ${pkgs.coreutils}/bin/printf '\n' >> "$config_tmp"
      ${pkgs.coreutils}/bin/cat "$source_file" >> "$config_tmp"
      ${pkgs.coreutils}/bin/install -m 0644 "$config_tmp" "$config_file"
      ${pkgs.coreutils}/bin/rm -f "$config_tmp"
    }

    save_backup_metadata() {
      backup_tmp="$(${pkgs.coreutils}/bin/mktemp "$state_dir/backup.XXXXXX")"
      ${pkgs.gawk}/bin/awk '
        /^\[Backup\]$/ { found = 1 }
        found && /^\[/ && $0 != "[Backup]" { exit }
        found { print }
      ' "$config_file" > "$backup_tmp"

      backup_version="$(${pkgs.gawk}/bin/awk -F= '$1 ~ /^[[:space:]]*version[[:space:]]*$/ { gsub(/[[:space:]]/, "", $2); print $2 }' "$backup_tmp")"
      backup_spicetify="$(${pkgs.gawk}/bin/awk -F= '$1 ~ /^[[:space:]]*with[[:space:]]*$/ { gsub(/[[:space:]]/, "", $2); print $2 }' "$backup_tmp")"
      if [ "$backup_version" != "$spotify_version" ] || [ "$backup_spicetify" != "$spicetify_version" ]; then
        ${pkgs.coreutils}/bin/rm -f "$backup_tmp"
        echo "error: Spicetify backup metadata does not match installed Spotify and Spicetify versions" >&2
        return 1
      fi

      ${pkgs.coreutils}/bin/chmod 0600 "$backup_tmp"
      ${pkgs.coreutils}/bin/mv "$backup_tmp" "$backup_metadata"
    }

    if [ -s "$backup_metadata" ]; then
      replace_backup_metadata "$backup_metadata"
    fi

    echo "==> Checking Flathub repository..."
    ${pkgs.flatpak}/bin/flatpak remote-add --user --if-not-exists flathub \
      https://flathub.org/repo/flathub.flatpakrepo

    echo "==> Checking Spotify installation..."
    if ! ${pkgs.flatpak}/bin/flatpak info --user "$APP_ID" >/dev/null 2>&1; then
      echo "==> Installing Spotify from Flathub..."
      ${pkgs.flatpak}/bin/flatpak install --user -y flathub "$APP_ID"
    fi

    spotify_revision="$(${pkgs.flatpak}/bin/flatpak info --user --show-commit "$APP_ID")"
    spotify_version="$(LC_ALL=C ${pkgs.flatpak}/bin/flatpak info --user "$APP_ID" | ${pkgs.gawk}/bin/awk '$1 == "Version:" { print $2 }')"
    if [ -z "$spotify_version" ]; then
      echo "error: Could not determine installed Spotify version" >&2
      exit 1
    fi
    spicetify_version="$(${pkgs.spicetify-cli}/bin/spicetify --version 2>&1)"
    desired_revision="${spicetifyManaged.bundle}:$spotify_revision:$spicetify_version"
    applied_revision=""
    if [ -r "$stamp_file" ]; then
      IFS= read -r applied_revision < "$stamp_file"
    fi

    if [ "$applied_revision" != "$desired_revision" ]; then
      echo "==> Backing up and applying managed Spicetify theme..."
      if ! ${pkgs.spicetify-cli}/bin/spicetify backup apply; then
        echo "==> Restoring Spotify before retrying..."
        if ${pkgs.spicetify-cli}/bin/spicetify restore; then
          ${pkgs.spicetify-cli}/bin/spicetify backup apply
        else
          echo "==> Reinstalling Spotify to recover clean application files..."
          ${pkgs.flatpak}/bin/flatpak install --user --reinstall -y flathub "$APP_ID"
          ${pkgs.spicetify-cli}/bin/spicetify backup apply
        fi
      fi

      save_backup_metadata
      stamp_tmp="$(${pkgs.coreutils}/bin/mktemp "$state_dir/revision.XXXXXX")"
      ${pkgs.coreutils}/bin/printf '%s\n' "$desired_revision" > "$stamp_tmp"
      ${pkgs.coreutils}/bin/mv "$stamp_tmp" "$stamp_file"
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

  systemd.user.tmpfiles.rules = [
    "r %h/.local/share/applications/spotify.desktop - - - -"
  ];

  systemd.user.services.spotify.serviceConfig.ExecStart =
    lib.mkForce "${spotify-spicetified}/bin/spotify-spicetified";
}
