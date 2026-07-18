{
  pkgs,
  richenLib,
  ...
}:
let
  sunshinePackage = pkgs.sunshine.override {
    cudaSupport = true;
  };
  headlessStreamScriptPath = pkgs.lib.makeBinPath [
    pkgs.coreutils
    pkgs.jq
    pkgs.systemd
    pkgs.wlr-randr
  ];
  gamepadUiScriptPath = pkgs.lib.makeBinPath [
    pkgs.coreutils
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

    OUTPUTS=$(wlr-randr --json)
    HEADLESS_DP=$(printf '%s\n' "$OUTPUTS" | jq -r '.[] | select(.description | contains("sisel muhendislik EK1080T4KV2") and contains("0x00005445")) | .name')
    mapfile -t PHYSICAL_OUTPUTS < <(printf '%s\n' "$OUTPUTS" | jq -r '.[] | select(.model == "BenQ GW2780" or .model == "Dell S2716DG" or .model == "DELL E2020H") | .name')

    if [ -z "$HEADLESS_DP" ]; then
      echo "sunshine-headless-set-resolution: could not find EK1080T4KV2 dummy output" >&2
      exit 1
    fi

    if [ "$(printf '%s\n' "$HEADLESS_DP" | wc -l)" -ne 1 ]; then
      echo "sunshine-headless-set-resolution: dummy output match is ambiguous: $HEADLESS_DP" >&2
      exit 1
    fi

    REFRESH=$(printf '%s\n' "$OUTPUTS" | jq -r \
      --arg output "$HEADLESS_DP" \
      --argjson width "$WIDTH" \
      --argjson height "$HEIGHT" \
      --argjson fps "$FPS" \
      '.[] | select(.name == $output) | .modes
       | map(select(.width == $width and .height == $height))
       | if length == 0 then empty
         else min_by(((.refresh - $fps) | if . < 0 then -. else . end)) | .refresh
         end')

    MODE_ARGS=()
    if [ -n "$REFRESH" ]; then
      MODE_ARGS=(--mode "''${WIDTH}x''${HEIGHT}@''${REFRESH}Hz")
    else
      MODE="''${WIDTH}x''${HEIGHT}@''${FPS}Hz"
      echo "sunshine-headless-set-resolution: no advertised ''${WIDTH}x''${HEIGHT} mode, trying custom $MODE" >&2
      MODE_ARGS=(--custom-mode "$MODE")
    fi

    wlr-randr \
      --output "$HEADLESS_DP" \
      --on \
      "''${MODE_ARGS[@]}" \
      --pos "0,0" \
      --scale "$SCALE"

    for output in "''${PHYSICAL_OUTPUTS[@]}"; do
      wlr-randr --output "$output" --off
    done
  '';
  sunshineHeadlessResetResolution = pkgs.writeShellScriptBin "sunshine-headless-reset-resolution" ''
    set -euo pipefail
    export PATH="/run/current-system/sw/bin:${headlessStreamScriptPath}:$PATH"

    RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    rm -f "$RUNTIME_DIR/sunshine-stream.env"

    OUTPUTS=$(wlr-randr --json)
    HEADLESS_DP=$(printf '%s\n' "$OUTPUTS" | jq -r '.[] | select(.description | contains("sisel muhendislik EK1080T4KV2") and contains("0x00005445")) | .name')
    if [ -n "$HEADLESS_DP" ] && [ "$(printf '%s\n' "$HEADLESS_DP" | wc -l)" -eq 1 ]; then
      wlr-randr --output "$HEADLESS_DP" --off || true
    fi

    output_for_model() {
      printf '%s\n' "$OUTPUTS" | jq -r --arg model "$1" 'first(.[] | select(.model == $model) | .name) // empty'
    }

    benq="$(output_for_model "BenQ GW2780")"
    center="$(output_for_model "Dell S2716DG")"
    side="$(output_for_model "DELL E2020H")"

    if [ -n "$benq" ] && [ -n "$center" ] && [ -n "$side" ]; then
      wlr-randr \
        --output "$benq" --on --mode 1920x1080@60.000000Hz --pos 0,0 --transform 90 --scale 1 \
        --output "$center" --on --mode 2560x1440@119.998001Hz --pos 1080,0 --transform normal --scale 1 --adaptive-sync disabled \
        --output "$side" --on --mode 1600x900@60.000000Hz --pos 3640,0 --transform 270 --scale 1
    else
      echo "sunshine-headless-reset-resolution: could not restore full physical monitor layout" >&2
    fi

    systemctl --user start swayidle.service || true
  '';
  sunshineSteamGamepadUiSession = pkgs.writeShellScriptBin "sunshine-steam-gamepad-ui-session" ''
    set -euo pipefail
    export PATH="/run/current-system/sw/bin:${gamepadUiScriptPath}:$PATH"
    export PROTON_ENABLE_WAYLAND=1

    exec steam -gamepadui
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
  sunshineApps = import ./_sunshine-apps.nix {
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

  services.sunshine = {
    enable = true;
    package = sunshinePackage;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = false;
    applications.apps = sunshineApps;
    settings = {
      capture = "kms";
      output_name = "0";
      encoder = "nvenc";
      adapter_name = "/dev/dri/by-path/pci-0000:01:00.0-render";
      vaapi_strict_rc_buffer = "disabled";
    };
  };

  services.avahi.openFirewall = false;

  systemd.user.services.sunshine.serviceConfig = {
    Environment = [ "LD_LIBRARY_PATH=/run/opengl-driver/lib" ];
  };

  security.wrappers.sunshine.capabilities = pkgs.lib.mkForce "cap_sys_admin,cap_sys_nice+pie";
  users.users.richen.extraGroups = [
    "uinput"
  ];
}
