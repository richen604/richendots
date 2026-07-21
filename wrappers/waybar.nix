{
  pkgs,
  richenLib,
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

    if [ -x "${richenLib.wrappers.mango-fern}/bin/mmsg" ]; then
      while IFS= read -r client; do
        [ -n "$client" ] && reasons+=("fullscreen: $client")
      done < <(
        ${pkgs.coreutils}/bin/timeout 1s ${richenLib.wrappers.mango-fern}/bin/mmsg get all-clients 2>/dev/null | ${pkgs.jq}/bin/jq -r '
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

  config = (pkgs.formats.json { }).generate "waybar-config" {
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
      spacing = 8;
    };
    "modules-left" = [
      "mango/workspaces"
      "wlr/taskbar"
    ];
    "modules-center" = [ ];
    "modules-right" = [
      "tray"
      # "network"
      "pulseaudio"
      # "pulseaudio#microphone"
      "keyboard-state"
      "custom/cpu-temp"
      "custom/gpu-temp"
      "custom/idle-inhibit"
      "clock"
      "custom/notification"
    ];
    "mango/window" = {
      format = "{title}";
    };
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
    "keyboard-state" = {
      numlock = false;
      scrolllock = false;
      capslock = true;
      format = "{icon}";
      "format-icons" = {
        locked = "Capslock";
        unlocked = "";
      };
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
    network = {
      interval = 2;
      "format-wifi" = "{essid} ({signalStrength}%)";
      "format-ethernet" = "󰈀 {ifname}";
      "format-linked" = " No IP ({ifname})";
      "format-disconnected" = " Disconnected";
      "tooltip-format" = "{ifname} {ipaddr}/{cidr} via {gwaddr}";
      "format-alt" = "↓{bandwidthDownBytes} ↑{bandwidthUpBytes}";
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
          months = "<span color='#ffead3'><b>{}</b></span>";
          days = "<span color='#ecc6d9'><b>{}</b></span>";
          weeks = "<span color='#99ffdd'><b>W{}</b></span>";
          weekdays = "<span color='#ffcc66'><b>{}</b></span>";
          today = "<span color='#ff6699'><b><u>{}</u></b></span>";
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
    "pulseaudio#microphone" = {
      format = "{format_source}";
      "format-source" = " {volume}%";
      tooltip = false;
      "format-source-muted" = " Muted";
      "on-click" = "pamixer --default-source -t";
      "on-scroll-up" = "pamixer --default-source -i 2";
      "on-scroll-down" = "pamixer --default-source -d 2";
      "scroll-step" = 5;
    };
    "custom/playerctl" = {
      format = "{2} <span>{0}</span>";
      "return-type" = "json";
      exec = "playerctl -p spotify metadata -f '{\"text\": \"{{markup_escape(title)}} - {{markup_escape(artist)}}  {{ duration(position) }}/{{ duration(mpris:length) }}\", \"tooltip\": \"{{markup_escape(title)}} - {{markup_escape(artist)}}  {{ duration(position) }}/{{ duration(mpris:length) }}\", \"alt\": \"{{status}}\", \"class\": \"{{status}}\"}' -F";
      tooltip = false;
      "on-click-middle" = "playerctl -p spotify previous";
      "on-click" = "playerctl -p spotify play-pause";
      "on-click-right" = "playerctl -p spotify next";
      "on-click-forward" = "playerctl -p spotify position 10+";
      "on-click-backward" = "playerctl -p spotify position 10-";
      "on-scroll-up" = "playerctl -p spotify volume 0.02+";
      "on-scroll-down" = "playerctl -p spotify volume 0.02-";
      "format-icons" = {
        Paused = " ";
        Playing = " ";
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
  };
  style = pkgs.writeText "style.css" ''

    @define-color bar-background rgba(0, 0, 0, 0.1);
    @define-color background rgba(14,18,15,0.4);
    @define-color foreground rgba(170,240,188,0.8);
    @define-color active-background rgba(30,55,52,0.4);
    @define-color active-foreground rgba(204,255,249,0.8);
    @define-color hover-background rgba(75,125,111,0.4);
    @define-color hover-foreground rgba(170,240,229,0.8);

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

    #language,
    #custom-weather,
    #custom-cpu-temp,
    #custom-gpu-temp,
    #custom-idle-inhibit,
    #window,
    #taskbar,
    #tags,
    #custom-playerctl,
    #clock,
    #battery,
    #pulseaudio,
    #cpu,
    #temperature,
    #network,
    #workspaces,
    #tray,
    #keyboard-state,
    #custom-notification {
      background: none;
      padding: 0px 10px;
      margin: 0px;
      margin-top: 5px;
      margin-bottom: 0px;
    }


    #tags {
      margin-left: 4px;
      padding-left: 10px;
      padding-right: 6px;
      background: none;
    }

    #tags button {
      border: none;
      transition-duration: 0.3s;
      background: none;
      box-shadow: inherit;
      text-shadow: inherit;
      color: @foreground;
      padding: 1px;
      padding-left: 1px;
      padding-right: 1px;
      margin-right: 4px;
    }

    #tags button {
      color: @foreground;
    }

    #tags button:not(.occupied):not(.focused) {
      font-size: 0;
      min-width: 0;
      min-height: 0;
      margin: -17px;
      padding: 0;
      color: transparent;
      background-color: transparent;
    }

    #tags button.occupied {
      color: @active-foreground;
    }

    #tags button.overview {
      color: @active-foreground;
    }

    #tags button:hover {
      color: @hover-foreground;
    }

    #tags button.focused {
      color: @active-foreground;
      margin-top: 5px;
      margin-bottom: 5px;
      padding-top: 1px;
      padding-bottom: 0px;
      border-radius: 3px;
    }

    #tags button.urgent {
      background-color: @hover-foreground;
      color: @active-foreground;
      margin-top: 5px;
      margin-bottom: 5px;
      padding-top: 1px;
      padding-bottom: 0px;
      border-radius: 3px;
    }

    #tray {
      background: none;
      margin-right: 4px;
      margin-left: 4px;
      padding-right: 8px;
      padding-left: 9px;
      padding-top: 2px;
      color: @active-foreground;
    }

    #network {
      background: none;
      margin-right: 4px;
      margin-left: 0px;
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
      background: transparent;
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

    #workspaces button.active {
      background-color: @active-background;
      color: @active-foreground;
      margin-top: 5px;
      margin-bottom: 5px;
      padding-top: 1px;
      padding-bottom: 0px;
      border-radius: 3px;
    }

    #workspaces button.urgent {
      background-color: #ef5e5e;
      color: @active-foreground;
      margin-top: 5px;
      margin-bottom: 5px;
      padding-top: 1px;
      padding-bottom: 0px;
      border-radius: 3px;
    }

    #language {
      background: none;
      color: @active-foreground;
      min-width: 24px;
    }

    #keyboard-state {
      background: none;
      color: @active-foreground;
      border: none;
      padding-top: 1px;
    }

    #window {
      background: none;
      margin-left: 0px;
      margin-right: 10px;
      color: @active-foreground;
    }

    #taskbar {
      background: none;
      margin-left: 10px;
      margin-right: 10px;
      color: #CCFFF9;
    }

    #taskbar.empty {
      margin-left: 0px;
      margin-right: 0px;
      padding-left: 10px;
      padding-right: 0px;
      border-radius: 0px;
      border-color: transparent;
      border: none;
      background-color: transparent;
    }

    #taskbar button {
      margin-right: 3px;
    }

    #taskbar button.minimized {
      background-color: @hover-background;
      color: @active-foreground;
      margin-top: 5px;
      margin-bottom: 5px;
      padding-top: 0px;
      padding-bottom: 0px;
      padding-left: 3px;
      padding-right: 3px;
      border-radius: 3px;
    }

    #taskbar button.urgent {
      background-color: @hover-foreground;
      color: @active-foreground;
      margin-top: 5px;
      margin-bottom: 5px;
      padding-top: 0px;
      padding-bottom: 0px;
      padding-left: 3px;
      padding-right: 3px;
      border-radius: 3px;
    }

    #taskbar button.active {
      background-color: @active-background;
      color: @active-foreground;
      margin-top: 5px;
      margin-bottom: 5px;
      padding-top: 0px;
      padding-bottom: 0px;
      padding-left: 3px;
      padding-right: 3px;
      border-radius: 3px;
    }

    #custom-playerctl {
      background: none;
      color: @active-foreground;
    }

    #clock {
      background: none;
      color: @active-foreground;
    }

    #pulseaudio {
      background: none;
      color: @active-foreground;
      margin-left: 0px;
    }

    #custom-cpu-temp,
    #custom-gpu-temp,
    #custom-idle-inhibit {
      background: none;
      color: @active-foreground;
    }

    #custom-cpu-temp.warm,
    #custom-gpu-temp.warm {
      color: #ffcc66;
    }

    #custom-cpu-temp.hot,
    #custom-gpu-temp.hot {
      color: #ef5e5e;
    }

    #custom-idle-inhibit.inactive {
      color: @foreground;
    }

    #battery {
      background: none;
      color: @active-foreground;
    }

    #custom-weather {
      background: none;
      color: @active-foreground;
      margin-left: 4px;
      padding-right: 7px;
      padding-top: 1px;
    }

    #custom-notification {
      background: none;
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
