{
  pkgs,
  richenLib,
  mangoPackage,
  outputs ? null,
  laptop ? false,
  ...
}:
let
  cpuTemp = pkgs.writeShellScriptBin "waybar-cpu-temp" ''
    shopt -s nullglob

    max_temp=""
    source="CPU"

    for hwmon in /sys/class/hwmon/hwmon*; do
      name=""
      if [ -r "$hwmon/name" ]; then
        name="$(<"$hwmon/name")"
      fi

      case "$name" in
        coretemp|k10temp|zenpower)
          for input in "$hwmon"/temp*_input; do
            [ -r "$input" ] || continue
            value="$(<"$input")"
            [ "$value" -gt 0 ] 2>/dev/null || continue
            temp=$((value / 1000))
            if [ -z "$max_temp" ] || [ "$temp" -gt "$max_temp" ]; then
              max_temp="$temp"
              label_file="''${input%_input}_label"
              if [ -r "$label_file" ]; then
                source="$(<"$label_file")"
              else
                source="$name"
              fi
            fi
          done
          ;;
      esac
    done

    if [ -z "$max_temp" ]; then
      exit 0
    fi

    class="cool"
    if [ "$max_temp" -ge 85 ]; then
      class="hot"
    elif [ "$max_temp" -ge 70 ]; then
      class="warm"
    fi

    printf '{"text":"%s°","tooltip":"%s %s°C","class":"%s","percentage":%s}\n' "$max_temp" "$source" "$max_temp" "$class" "$max_temp"
  '';

  gpuTemp = pkgs.writeShellScriptBin "waybar-gpu-temp" ''
    if ! command -v nvidia-smi >/dev/null 2>&1; then
      exit 0
    fi

    line=""
    while IFS= read -r line; do
      break
    done < <(nvidia-smi --query-gpu=temperature.gpu,utilization.gpu,memory.used,memory.total,power.draw --format=csv,noheader,nounits 2>/dev/null)

    [ -n "$line" ] || exit 0

    IFS=',' read -r temp util mem_used mem_total power <<< "$line"
    temp="''${temp// /}"
    util="''${util// /}"
    mem_used="''${mem_used// /}"
    mem_total="''${mem_total// /}"
    power="''${power## }"
    power="''${power%% }"

    [ "$temp" -gt 0 ] 2>/dev/null || exit 0

    class="cool"
    if [ "$temp" -ge 85 ]; then
      class="hot"
    elif [ "$temp" -ge 70 ]; then
      class="warm"
    fi

    tooltip="GPU ''${temp}°C, ''${util}% used, ''${mem_used}/''${mem_total} MiB VRAM, ''${power}W"
    printf '{"text":"%s°","tooltip":"%s","class":"%s","percentage":%s}\n' "$temp" "$tooltip" "$class" "$temp"
  '';

  idleStatus = pkgs.writeShellScriptBin "waybar-idle-status" ''
    reasons=()

    if ${pkgs.systemd}/bin/systemctl --user is-active --quiet waybar-manual-idle-inhibit.service 2>/dev/null; then
      reasons+=("manual")
    fi

    if [ -x "${pkgs.pipewire}/bin/pw-dump" ]; then
      while IFS= read -r stream; do
        [ -n "$stream" ] && reasons+=("media: $stream")
      done < <(
        ${pkgs.coreutils}/bin/timeout 1s ${pkgs.pipewire}/bin/pw-dump 2>/dev/null | ${pkgs.jq}/bin/jq -r '
          [ .[]
            | select(.type == "PipeWire:Interface:Node")
            | select(.info.state == "running")
            | .info.props
            | select((."media.class" // "") | startswith("Stream/"))
            | (."application.name" // ."media.name" // ."node.name" // empty)
          ]
          | unique[]?
        ' 2>/dev/null
      )
    fi

    if [ -x "${mangoPackage}/bin/mmsg" ]; then
      while IFS= read -r client; do
        [ -n "$client" ] && reasons+=("fullscreen: $client")
      done < <(
        ${pkgs.coreutils}/bin/timeout 1s ${mangoPackage}/bin/mmsg get all-clients 2>/dev/null | ${pkgs.jq}/bin/jq -r '
          .clients[]?
          | select(.is_visible == true)
          | select(
              (.is_fullscreen // false) == true
              or (.fullscreen // false) == true
              or (.is_fake_fullscreen // false) == true
              or (.fake_fullscreen // false) == true
              or (.fullscreen_state // "") != ""
              or (.state.fullscreen // false) == true
            )
          | (.title // .appid // "client")
        ' 2>/dev/null
      )
    fi

    if [ "''${#reasons[@]}" -gt 0 ]; then
      tooltip="Idle inhibited"
      for reason in "''${reasons[@]}"; do
        tooltip+=$'\n'"$reason"
      done
      ${pkgs.jq}/bin/jq -cn --arg text "󰅶" --arg tooltip "$tooltip" --arg class "active" \
        '{text: $text, tooltip: $tooltip, class: $class}'
    else
      ${pkgs.jq}/bin/jq -cn --arg text "󰾪" --arg tooltip $'Idle not inhibited\nClick for manual inhibit' --arg class "inactive" \
        '{text: $text, tooltip: $tooltip, class: $class}'
    fi
  '';

  idleToggle = pkgs.writeShellScriptBin "waybar-idle-toggle" ''
    if ${pkgs.systemd}/bin/systemctl --user is-active --quiet waybar-manual-idle-inhibit.service 2>/dev/null; then
      ${pkgs.systemd}/bin/systemctl --user stop waybar-manual-idle-inhibit.service
    else
      ${pkgs.systemd}/bin/systemctl --user start waybar-manual-idle-inhibit.service
    fi

    ${pkgs.procps}/bin/pkill -RTMIN+9 waybar 2>/dev/null || true
  '';

  config = (pkgs.formats.json { }).generate "waybar-config" (
    {
      layer = "top";
      position = "top";
      exclusive = true;
      passthrough = false;
      "gtk-layer-shell" = true;
      ipc = false;
      reload_style_on_change = false;
      height = 40;
      tray = {
        interval = 1;
        "icon-size" = 18;
        "show-passive-items" = true;
        spacing = 8;
      };
      "modules-left" = [
        "mango/workspaces"
        "wlr/taskbar"
      ];
      "modules-center" = [ ];
      "modules-right" = [
        "tray"
        "pulseaudio"
        "custom/cpu-temp"
        "custom/gpu-temp"
        "custom/replay"
      ]
      ++ pkgs.lib.optionals laptop [
        "backlight"
        "battery"
      ]
      ++ [
        "custom/idle-inhibit"
        "clock"
        "custom/notification"
      ];
      "mango/workspaces" = {
        "format" = "{value}";
        "hide-empty" = true;
        "on-click" = "activate";
      };
      "custom/notification" = {
        tooltip = false;
        format = "{icon}";
        "format-icons" = {
          notification = "<span foreground='red'><sup></sup></span>";
          none = "  ";
          "dnd-notification" = "<span foreground='red'><sup></sup></span>";
          "dnd-none" = "";
          "inhibited-notification" = "<span foreground='red'><sup></sup></span>";
          "inhibited-none" = "";
          "dnd-inhibited-notification" = "<span foreground='red'><sup></sup></span>";
          "dnd-inhibited-none" = "";
        };
        "return-type" = "json";
        "exec-if" = "which swaync-client";
        exec = "swaync-client -swb";
        "on-click" = "sleep 0.1s && swaync-client -t -sw";
        "on-click-right" = "swaync-client -d -sw";
        escape = true;
      };
      "custom/cpu-temp" = {
        interval = 2;
        format = " {text}";
        exec = "${cpuTemp}/bin/waybar-cpu-temp";
        "return-type" = "json";
        "hide-empty-text" = true;
      };
      "custom/gpu-temp" = {
        interval = 2;
        format = "󰢮 {text}";
        exec = "${gpuTemp}/bin/waybar-gpu-temp";
        "return-type" = "json";
        "hide-empty-text" = true;
      };
      "custom/replay" = {
        interval = 5;
        signal = 10;
        format = "{text}";
        exec = "replay-status";
        "on-click" = "replay-mode-menu";
        "on-click-right" = "replay-save";
        "on-click-middle" = "replay-recent";
        "return-type" = "json";
        tooltip = true;
      };
      "custom/idle-inhibit" = {
        interval = 5;
        signal = 9;
        format = "{text}";
        exec = "${idleStatus}/bin/waybar-idle-status";
        "on-click" = "${idleToggle}/bin/waybar-idle-toggle";
        "return-type" = "json";
        tooltip = true;
      };
      "wlr/taskbar" = {
        format = "{icon}";
        "icon-size" = 22;
        "all-outputs" = false;
        "tooltip-format" = "{title}";
        markup = true;
        "on-click" = "activate";
        "on-click-right" = "close";
        "ignore-list" = [
          "Rofi"
          "wofi"
        ];
      };
      clock = {
        format = "{:%H:%M} ";
        "format-alt" = "{:%A, %b %d} ";
        "tooltip-format" = "{:%Y}";
        calendar = {
          mode = "year";
          "mode-mon-col" = 3;
          "weeks-pos" = "right";
          "on-scroll" = 1;
          format = {
            months = "<span color='${richenLib.theme.acc.s."9"}'><b>{}</b></span>";
            days = "<span color='${richenLib.theme.syntax.function}'><b>{}</b></span>";
            weeks = "<span color='${richenLib.theme.acc.p."7"}'><b>W{}</b></span>";
            weekdays = "<span color='${richenLib.theme.ui.warning}'><b>{}</b></span>";
            today = "<span color='${richenLib.theme.ui.error}'><b><u>{}</u></b></span>";
          };
        };
      };
      pulseaudio = {
        format = "{icon} {volume}%";
        tooltip = false;
        "format-muted" = " Muted";
        "on-click" = "pamixer -t";
        "on-scroll-up" = "pamixer -i 2";
        "on-scroll-down" = "pamixer -d 2";
        "scroll-step" = 5;
        "format-icons" = {
          headphone = "";
          "hands-free" = "";
          headset = "";
          phone = "";
          portable = "";
          car = "";
          default = [
            ""
            ""
            ""
          ];
        };
      };
      battery = {
        bat = "BAT0";
        interval = 1800;
        states = {
          warning = 20;
          critical = 10;
        };
        format = "{icon}";
        "format-icons" = [
          ""
          ""
          ""
          ""
          ""
        ];
        "max-length" = 25;
      };
    }
    // pkgs.lib.optionalAttrs (outputs != null) {
      output = outputs;
    }
    // pkgs.lib.optionalAttrs laptop {
      backlight = {
        interval = 2;
        device = "amdgpu_bl0";
        format = "{icon} {percent}%";
        "format-icons" = [
          "󰖔"
          "󰖨"
        ];
        "on-scroll-up" = "brightnessctl set +1%";
        "on-scroll-down" = "brightnessctl set 1%-";
        "smooth-scrolling-threshold" = 1;
      };
    }
  );
  waybarTheme = import ./_theme.nix { inherit (richenLib) theme; };
  defineGtkColors =
    colors:
    pkgs.lib.concatStringsSep "\n" (
      pkgs.lib.mapAttrsToList (name: value: "@define-color ${name} ${value};") colors
    );
  style = pkgs.writeText "style.css" ''

    ${defineGtkColors waybarTheme.colors}

    * {
      border: none;
      font-family: GohuFont uni14 Nerd Font Propo;
      font-weight: 700;
      font-size: 13px;
      min-height: 0;
    }

    window#waybar {
      background: none;
      margin: 0px;
      padding: 0px;
    }

    tooltip {
      background: none;
      color: @active-foreground;
    }

    #custom-cpu-temp,
    #custom-gpu-temp,
    #custom-replay,
    #custom-idle-inhibit,
    #taskbar,
    #clock,
    #battery,
    #pulseaudio,
    #workspaces,
    #tray,
    #custom-notification {
      background: none;
      padding: 0px 10px;
      margin: 5px 0px 0px;
    }

    #tray {
      margin-right: 4px;
      margin-left: 4px;
      padding-right: 8px;
      padding-left: 9px;
      padding-top: 2px;
      color: @active-foreground;
    }

    #workspaces {
      border-radius: 4px;
      margin-left: 4px;
      padding-left: 10px;
      padding-right: 6px;
    }

    #workspaces button {
      border: none;
      background: none;
      box-shadow: inherit;
      text-shadow: inherit;
      color: @foreground;
      padding: 1px;
      padding-left: 3px;
      padding-right: 3px;
      margin-right: 1px;
      margin-left: 1px;
    }

    #workspaces button.hidden {
      color: transparent;
      background-color: transparent;
    }

    #workspaces button.visible {
      color: @foreground;
    }

    #workspaces button:hover {
      color: @active-foreground;
    }

    #workspaces button.active,
    #workspaces button.urgent {
      color: @active-foreground;
      margin-top: 5px;
      margin-bottom: 5px;
      padding: 1px 3px 0px;
      border-radius: 3px;
    }

    #workspaces button.active {
      background-color: @active-background;
    }

    #workspaces button.urgent {
      background-color: @urgent;
    }

    #taskbar {
      margin-left: 10px;
      margin-right: 10px;
      color: @active-foreground;
    }

    #taskbar.empty {
      margin-left: 0px;
      margin-right: 0px;
      padding-right: 0px;
      border-radius: 0px;
    }

    #taskbar button {
      margin-right: 3px;
    }

    #taskbar button.minimized,
    #taskbar button.urgent,
    #taskbar button.active {
      color: @active-foreground;
      margin-top: 5px;
      margin-bottom: 5px;
      padding: 0px 3px;
      border-radius: 3px;
    }

    #taskbar button.minimized {
      background-color: @hover-background;
    }

    #taskbar button.active {
      background-color: @active-background;
    }

    #taskbar button.urgent {
      background-color: @urgent;
    }

    #clock {
      color: @active-foreground;
    }

    #pulseaudio {
      color: @active-foreground;
      margin-left: 0px;
    }

    #custom-cpu-temp,
    #custom-gpu-temp,
    #custom-replay,
    #custom-idle-inhibit {
      color: @active-foreground;
    }

    #custom-cpu-temp.warm,
    #custom-gpu-temp.warm {
      color: @warning;
    }

    #custom-cpu-temp.hot,
    #custom-gpu-temp.hot {
      color: @urgent;
    }

    #custom-idle-inhibit.inactive {
      color: @foreground;
    }

    #custom-replay {
      transition-duration: 0.2s;
      padding-left: 7px;
      padding-right: 7px;
    }

    #custom-replay.off {
      color: @foreground;
    }

    #custom-replay.primary,
    #custom-replay.all {
      background-color: @active-background;
      color: @urgent;
      border-radius: 3px;
    }

    #custom-replay.degraded {
      background-color: @urgent;
      color: @active-foreground;
      border-radius: 3px;
    }

    #battery {
      color: @active-foreground;
    }

    ${pkgs.lib.optionalString laptop ''
      #backlight {
        background: none;
        color: @active-foreground;
        margin-right: 4px;
      }
    ''}

    #custom-notification {
      color: @active-foreground;
      min-width: 18px;
    }

  '';
in
richenLib.lib.wrapPackage {
  package = pkgs.waybar;
  filesToPatch = [ "share/systemd/user/waybar.service" ];
  flags = {
    "--config" = config;
    "--style" = style;
  };
  passthru = {
    config.path = config;
    style.path = style;
  };
}
