{
  inputs,
  pkgs,
  richenLib,
  ...
}:
let
  sunshinePkgs = import inputs.sunshineNixpkgs {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
  sunshinePackage = sunshinePkgs.sunshine;
  headlessStreamScriptPath = pkgs.lib.makeBinPath [
    pkgs.coreutils
    pkgs.jq
    pkgs.systemd
    pkgs.wlr-randr
  ];
  gamepadUiScriptPath = pkgs.lib.makeBinPath [
    pkgs.coreutils
    pkgs.gamescope
    pkgs.steam
    pkgs.systemd
  ];
  sunshineHeadlessSetResolution = pkgs.writeShellScriptBin "sunshine-headless-set-resolution" ''
    set -euo pipefail
    export PATH="/run/current-system/sw/bin:${headlessStreamScriptPath}:$PATH"

    : "''${SUNSHINE_CLIENT_WIDTH:?SUNSHINE_CLIENT_WIDTH is required}"
    : "''${SUNSHINE_CLIENT_HEIGHT:?SUNSHINE_CLIENT_HEIGHT is required}"
    : "''${SUNSHINE_CLIENT_FPS:?SUNSHINE_CLIENT_FPS is required}"

    WIDTH="''${SUNSHINE_CLIENT_WIDTH}"
    HEIGHT="''${SUNSHINE_CLIENT_HEIGHT}"
    FPS="''${SUNSHINE_CLIENT_FPS}"
    SCALE="1"

    if [ "$WIDTH" = "3200" ] && [ "$HEIGHT" = "2000" ]; then
      SCALE="1.5"
    fi

    RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    STREAM_ENV="$RUNTIME_DIR/sunshine-stream.env"
    install -m 0600 /dev/null "$STREAM_ENV"
    {
      printf 'SUNSHINE_CLIENT_WIDTH=%s\n' "$WIDTH"
      printf 'SUNSHINE_CLIENT_HEIGHT=%s\n' "$HEIGHT"
      printf 'SUNSHINE_CLIENT_FPS=%s\n' "$FPS"
    } > "$STREAM_ENV"

    systemctl --user stop swayidle.service || true

    HEADLESS_DP=$(wlr-randr --json | jq -r '.[] | select(.description | contains("sisel muhendislik EK1080T4KV2") and contains("0x00005445")) | .name')

    if [ -z "$HEADLESS_DP" ]; then
      echo "sunshine-headless-set-resolution: could not find EK1080T4KV2 dummy output" >&2
      exit 1
    fi

    if [ "$(printf '%s\n' "$HEADLESS_DP" | wc -l)" -ne 1 ]; then
      echo "sunshine-headless-set-resolution: dummy output match is ambiguous: $HEADLESS_DP" >&2
      exit 1
    fi

    wlr-randr \
      --output "$HEADLESS_DP" \
      --on \
      --custom-mode "''${WIDTH}x''${HEIGHT}@''${FPS}Hz" \
      --pos "0,0" \
      --scale "$SCALE"
  '';
  sunshineHeadlessResetResolution = pkgs.writeShellScriptBin "sunshine-headless-reset-resolution" ''
    set -euo pipefail
    export PATH="/run/current-system/sw/bin:${headlessStreamScriptPath}:$PATH"

    RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    rm -f "$RUNTIME_DIR/sunshine-stream.env"

    HEADLESS_DP=$(wlr-randr --json | jq -r '.[] | select(.description | contains("sisel muhendislik EK1080T4KV2") and contains("0x00005445")) | .name')
    if [ -n "$HEADLESS_DP" ] && [ "$(printf '%s\n' "$HEADLESS_DP" | wc -l)" -eq 1 ]; then
      wlr-randr --output "$HEADLESS_DP" --scale 1 || true
    fi

    systemctl --user start swayidle.service || true
  '';
  sunshineSteamGamepadUiSession = pkgs.writeShellScriptBin "sunshine-steam-gamepad-ui-session" ''
    set -euo pipefail
    export PATH="/run/current-system/sw/bin:${gamepadUiScriptPath}:$PATH"

    RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    STREAM_ENV="$RUNTIME_DIR/sunshine-stream.env"

    if [ -r "$STREAM_ENV" ]; then
      . "$STREAM_ENV"
    fi

    WIDTH="''${SUNSHINE_CLIENT_WIDTH:-1920}"
    HEIGHT="''${SUNSHINE_CLIENT_HEIGHT:-1080}"
    FPS="''${SUNSHINE_CLIENT_FPS:-60}"

    exec gamescope \
      -b \
      -f \
      -W "$WIDTH" \
      -H "$HEIGHT" \
      -w "$WIDTH" \
      -h "$HEIGHT" \
      -r "$FPS" \
      -- \
      steam -gamepadui
  '';
  sunshineSteamGamepadUi = pkgs.writeShellScriptBin "sunshine-steam-gamepad-ui" ''
    set -euo pipefail
    export PATH="/run/current-system/sw/bin:${gamepadUiScriptPath}:$PATH"

    UNIT="sunshine-steam-gamepad-ui"
    systemctl --user stop "$UNIT.service" >/dev/null 2>&1 || true
    systemd-run --user --collect --unit="$UNIT" \
      "${sunshineSteamGamepadUiSession}/bin/sunshine-steam-gamepad-ui-session" >/dev/null
  '';
  sunshineCloseSteamGamepadUi = pkgs.writeShellScriptBin "sunshine-close-steam-gamepad-ui" ''
    set -uo pipefail
    export PATH="/run/current-system/sw/bin:${gamepadUiScriptPath}:$PATH"

    systemctl --user stop sunshine-steam-gamepad-ui.service >/dev/null 2>&1 || true
  '';
  sunshineApps = import ./apps.nix {
    inherit
      sunshinePackage
      sunshineHeadlessSetResolution
      sunshineHeadlessResetResolution
      sunshineSteamGamepadUi
      sunshineCloseSteamGamepadUi
      ;
  };
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
  };

  services.sunshine = {
    enable = true;
    package = sunshinePackage;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
    applications = {
      apps = sunshineApps;
    };
    settings = {
      capture = "kms";
      output_name = "0";
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
      export PATH="/run/current-system/sw/bin:$PATH"
      RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
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
        gamemoderun prime-run "$@"
    '')
  ];
}
