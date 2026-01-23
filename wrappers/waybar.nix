{
  inputs,
  pkgs,
  ...
}:

(inputs.wrappers.wrapperModules.waybar.apply {
  pkgs = pkgs;
  settings = {
    layer = "top";
    position = "top";
    exclusive = true;
    passthrough = false;
    "gtk-layer-shell" = true;
    ipc = false;
    reload_style_on_change = true;
    height = 45;
    "modules-left" = [
      # "dwl/tags"
      "ext/workspaces"
      "wlr/taskbar"
      "dwl/window"
    ];
    "modules-right" = [
      "tray"
      "network"
      "pulseaudio"
      "cpu"
      "temperature"
      "backlight"
      "clock"
      "custom/notification"
      "custom/power"
    ];
    "dwl/tags" = {
      "num-tags" = 9;
    };
    "dwl/window" = {
      format = "{}";
    };
    "ext/workspaces" = {
      "format" = "{icon}";
      "ignore-hidden" = true;
      "on-click" = "activate";
      "sort-by-id" = true;
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
    cpu = {
      interval = 2;
      format = " {load}%";
    };
    temperature = {
      "thermal-zone" = 2;
      "hwmon-path" = "/sys/class/hwmon/hwmon1/temp1_input";
      "critical-threshold" = 10;
      "format-critical" = " {temperatureC}°C";
      format = "";
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
    tray = {
      interval = 1;
      "icon-size" = 21;
      spacing = 10;
    };
    network = {
      interval = 2;
      "format-wifi" = "{essid} ({signalStrength}%)";
      "format-ethernet" = "󰈀 {ifname}";
      "format-linked" = "\uf059 No IP ({ifname})";
      "format-disconnected" = "\uf071 Disconnected";
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
    "custom/power" = {
      format = "";
      tooltip = false;
      "on-click" = "wlogout -b 6 --protocol layer-shell";
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
      bat = "hidpp_battery_0";
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
  "style.css".content = ''

    @define-color bar-background rgba(0, 0, 0, 0.1);
    @define-color background rgba(14,18,15,0.4);
    @define-color foreground rgba(170,240,188,0.8);
    @define-color active-background rgba(30,55,52,0.4);
    @define-color active-foreground rgba(204,255,249,0.8);
    @define-color hover-background rgba(75,125,111,0.4);
    @define-color hover-foreground rgba(170,240,229,0.8);

    * {
      border: none;
      font-family: Maple Mono NF CN;
      font-weight: 800;
      font-size: 12px;
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
    #window,
    #taskbar,
    #tags,
    #custom-playerctl,
    #clock,
    #battery,
    #pulseaudio,
    #cpu,
    #temperature,
    #backlight,
    #network,
    #workspaces,
    #tray,
    #keyboard-state,
    #custom-notification,
    #custom-power {
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

    #cpu  {
      background: none;
      color: @active-foreground;
    }

    #temperature {
      background: none;
      color: @active-foreground;
    }

    #backlight {
      background: none;
      color: @active-foreground;
      margin-right: 4px;
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

    #custom-power {
      background: none;
      color: @active-foreground;
      margin-left: 0px;
      margin-right: 4px;
      padding-right: 14px;
    }
  '';
}).wrapper
