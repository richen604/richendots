{
  pkgs,
  richenLib,
  ...
}:
let
  mango = richenLib.wrappers.mango;
  sunshineSetResolution = pkgs.writeShellScriptBin "sunshine-set-resolution" ''
    set -euo pipefail

    : "''${SUNSHINE_CLIENT_WIDTH:?SUNSHINE_CLIENT_WIDTH is required}"
    : "''${SUNSHINE_CLIENT_HEIGHT:?SUNSHINE_CLIENT_HEIGHT is required}"
    : "''${SUNSHINE_CLIENT_FPS:?SUNSHINE_CLIENT_FPS is required}"

    RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}"
    STREAM_ENV="$RUNTIME_DIR/sunshine-stream.env"
    ${pkgs.coreutils}/bin/install -m 0600 /dev/null "$STREAM_ENV"
    {
      ${pkgs.coreutils}/bin/printf 'SUNSHINE_CLIENT_WIDTH=%s\n' "''${SUNSHINE_CLIENT_WIDTH}"
      ${pkgs.coreutils}/bin/printf 'SUNSHINE_CLIENT_HEIGHT=%s\n' "''${SUNSHINE_CLIENT_HEIGHT}"
      ${pkgs.coreutils}/bin/printf 'SUNSHINE_CLIENT_FPS=%s\n' "''${SUNSHINE_CLIENT_FPS}"
    } > "$STREAM_ENV"

    MAIN_DP=$(${pkgs.wlr-randr}/bin/wlr-randr --json | ${pkgs.jq}/bin/jq -r '.[] | select(.description | contains("Dell S2716DG")) | .name')

    if [ -z "$MAIN_DP" ]; then
      echo "sunshine-set-resolution: could not find Dell S2716DG output" >&2
      exit 1
    fi

    if [ "$(${pkgs.coreutils}/bin/printf '%s\n' "$MAIN_DP" | ${pkgs.coreutils}/bin/wc -l)" -ne 1 ]; then
      echo "sunshine-set-resolution: monitor match is ambiguous: $MAIN_DP" >&2
      exit 1
    fi

    RIGHT_DP=$(${pkgs.wlr-randr}/bin/wlr-randr --json | ${pkgs.jq}/bin/jq -r '.[] | select(.description | contains("DELL E2020H")) | .name')

    ${pkgs.wlr-randr}/bin/wlr-randr \
      --output "$MAIN_DP" \
      --custom-mode "''${SUNSHINE_CLIENT_WIDTH}x''${SUNSHINE_CLIENT_HEIGHT}@''${SUNSHINE_CLIENT_FPS}Hz" \
      --pos "1080,0"

    if [ -n "$RIGHT_DP" ]; then
      ${pkgs.wlr-randr}/bin/wlr-randr --output "$RIGHT_DP" --pos "$((1080 + SUNSHINE_CLIENT_WIDTH)),0"
    fi

    ${mango}/bin/mmsg -d 'focusmon,model:Dell S2716DG' || true
  '';
  sunshineResetResolution = pkgs.writeShellScriptBin "sunshine-reset-resolution" ''
    set -euo pipefail

    RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}"
    ${pkgs.coreutils}/bin/rm -f "$RUNTIME_DIR/sunshine-stream.env"
    ${mango}/bin/mmsg -d reload_config
  '';
  sunshineSteamBigPicture = pkgs.writeShellScriptBin "sunshine-steam-big-picture" ''
    set -uo pipefail

    LOG_DIR="''${XDG_RUNTIME_DIR:-/tmp}/sunshine-steam-big-picture"
    ${pkgs.coreutils}/bin/mkdir -p "$LOG_DIR"

    {
      ${pkgs.coreutils}/bin/date --iso-8601=seconds
      ${pkgs.coreutils}/bin/printf 'WAYLAND_DISPLAY=%s\n' "''${WAYLAND_DISPLAY:-}"
      ${pkgs.coreutils}/bin/printf 'DISPLAY=%s\n' "''${DISPLAY:-}"
      ${pkgs.coreutils}/bin/printf 'XDG_CURRENT_DESKTOP=%s\n' "''${XDG_CURRENT_DESKTOP:-}"
      UNIT="sunshine-steam-big-picture-$(${pkgs.coreutils}/bin/date +%s)"
      ${pkgs.systemd}/bin/systemd-run --user --collect --unit="$UNIT" \
        --setenv=WAYLAND_DISPLAY="''${WAYLAND_DISPLAY:-}" \
        --setenv=DISPLAY="''${DISPLAY:-}" \
        --setenv=XDG_CURRENT_DESKTOP="''${XDG_CURRENT_DESKTOP:-}" \
        ${pkgs.steam}/bin/steam steam://open/bigpicture
      rc=$?
      ${pkgs.coreutils}/bin/printf 'steam-open-exit=%s\n' "$rc"
      ${pkgs.coreutils}/bin/sleep 8
    } >> "$LOG_DIR/launch.log" 2>&1

    exit 0
  '';
  sunshineCloseSteamBigPicture = pkgs.writeShellScriptBin "sunshine-close-steam-big-picture" ''
    set -uo pipefail

    UNIT="sunshine-close-steam-big-picture-$(${pkgs.coreutils}/bin/date +%s)"
    ${pkgs.systemd}/bin/systemd-run --user --collect --unit="$UNIT" \
      --setenv=WAYLAND_DISPLAY="''${WAYLAND_DISPLAY:-}" \
      --setenv=DISPLAY="''${DISPLAY:-}" \
      --setenv=XDG_CURRENT_DESKTOP="''${XDG_CURRENT_DESKTOP:-}" \
      ${pkgs.steam}/bin/steam steam://close/bigpicture >/dev/null 2>&1 || true
  '';
in
{
  hardware.uinput.enable = true;

  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos;
  };

  programs.gamescope = {
    enable = true;
    capSysNice = false;
    enableWsi = true;
  };

  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
    applications = {
      apps = [
        {
          name = "Desktop";
          prep-cmd = [
            {
              do = "${sunshineSetResolution}/bin/sunshine-set-resolution";
              undo = "${sunshineResetResolution}/bin/sunshine-reset-resolution";
            }
          ];
          exclude-global-prep-cmd = "false";
          auto-detach = "true";
        }
        {
          name = "Steam Big Picture";
          prep-cmd = [
            {
              do = "${sunshineSetResolution}/bin/sunshine-set-resolution";
              undo = "${sunshineResetResolution}/bin/sunshine-reset-resolution";
            }
            {
              do = "";
              undo = "${sunshineCloseSteamBigPicture}/bin/sunshine-close-steam-big-picture";
            }
          ];
          detached = [
            "${sunshineSteamBigPicture}/bin/sunshine-steam-big-picture"
          ];
          exclude-global-prep-cmd = "false";
          auto-detach = "true";
        }
      ];
    };
    settings = {
      capture = "kms";
      output_name = "2";
      encoder = "vaapi";
      adapter_name = "/dev/dri/by-path/pci-0000:03:00.0-render";
      vaapi_strict_rc_buffer = "disabled";
    };
  };

  programs.gamemode.enable = true;

  users.users.richen.extraGroups = [
    "gamemode"
    "uinput"
  ];

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "steam-game-run" ''
      export PATH=/run/current-system/sw/bin:$PATH
      RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}"
      STREAM_ENV="$RUNTIME_DIR/sunshine-stream.env"

      if [ -r "$STREAM_ENV" ]; then
        . "$STREAM_ENV"
      fi

      WIDTH="''${SUNSHINE_CLIENT_WIDTH:-2560}"
      HEIGHT="''${SUNSHINE_CLIENT_HEIGHT:-1440}"
      FPS="''${SUNSHINE_CLIENT_FPS:-144}"

      exec gamescope \
        -b \
        -f \
        -W "$WIDTH" \
        -H "$HEIGHT" \
        -w "$WIDTH" \
        -h "$HEIGHT" \
        -r "$FPS" \
        --force-windows-fullscreen \
        --force-grab-cursor \
        -g \
        -- \
        ${pkgs.gamemode}/bin/gamemoderun /run/current-system/sw/bin/prime-run "$@"
    '')
  ];
}
