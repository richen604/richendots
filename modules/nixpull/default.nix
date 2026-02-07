{
  config,
  pkgs,
  ...
}:

# usage:
#
# note: user is hardcoded to "richen"
#
# client mode:
#   services.nixpull = {
#     enable = true;
#     mode = "client";
#     checkInterval = "hourly";  # or "weekly" or "Mon *-*-* 03:00:00" for mondays at 3am
#     enableNotifications = true;
#   };
#
# server mode:
#   services.nixpull = {
#     enable = true;
#     mode = "server";
#     autoBuild = true;
#     buildInterval = "Mon *-*-* 03:00:00";  # weekly at 3am on mondays
#   };
let
  cfg = config.services.nixpull;

  nixpullPackage = pkgs.callPackage (
    pkgs.writeScriptBin "nixpull" ''
      #!/usr/bin/env bash
      PATH=$PATH:${
        pkgs.lib.makeBinPath [
          pkgs.coreutils
          pkgs.openssh
          pkgs.nix
          pkgs.jq
          pkgs.gum
          pkgs.dix
        ]
      }
      ${builtins.readFile ./nixpull.sh}
    ''
  );

in
{
  options.services.nixpull = {
    enable = pkgs.lib.mkEnableOption "nixpull system update service";

    mode = pkgs.lib.mkOption {
      type = pkgs.lib.types.enum [
        "server"
        "client"
      ];
      description = "server: build configs, client: fetch and apply updates";
    };

    flake = pkgs.lib.mkOption {
      type = pkgs.lib.types.str;
      default = "";
      description = "Flake reference for nixpull package (server mode only)";
    };

    storeDir = pkgs.lib.mkOption {
      type = pkgs.lib.types.str;
      default = "/tmp/nixpull";
      description = "Directory where build paths are stored";
    };

    # Client-specific options
    checkInterval = pkgs.lib.mkOption {
      type = pkgs.lib.types.str;
      default = "hourly";
      description = "how often to check for updates (client mode). examples: hourly, daily, Mon *-*-* 03:00:00";
    };

    enableNotifications = pkgs.lib.mkOption {
      type = pkgs.lib.types.bool;
      default = true;
      description = "Enable desktop notifications when updates are available (client mode only)";
    };

    # Server-specific options
    buildInterval = pkgs.lib.mkOption {
      type = pkgs.lib.types.str;
      default = "hourly";
      description = "how often to build configs (server mode). examples: hourly, daily, Mon *-*-* 03:00:00";
    };

    autoBuild = pkgs.lib.mkOption {
      type = pkgs.lib.types.bool;
      default = false;
      description = "automatically build configs on schedule (server mode). if false, run 'nixpull build' manually";
    };
  };

  config = pkgs.lib.mkIf cfg.enable {
    environment.systemPackages = [ nixpullPackage ];

    # client mode: check for updates (system timer triggers user service)
    systemd.timers.nixpull-check = pkgs.lib.mkIf (cfg.mode == "client") {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.checkInterval;
        Persistent = true;
        RandomizedDelaySec = "5m";
      };
    };

    # client mode: check for updates (system service)
    systemd.services.nixpull-check = pkgs.lib.mkIf (cfg.mode == "client") {
      description = "check for nixos system updates";
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };

      script = ''
        if ${nixpullPackage}/bin/nixpull check; then
          echo "update available. run 'nixpull pull' to apply."
          ${
            if cfg.enableNotifications then
              ''
                # trigger user notification service
                ${pkgs.systemd}/bin/systemctl --user -M richen@ start nixpull-notify.service
              ''
            else
              ""
          }
        else
          echo "no updates available"
        fi
      '';
    };

    # client mode: notification service (runs as user)
    systemd.user.services.nixpull-notify =
      pkgs.lib.mkIf (cfg.mode == "client" && cfg.enableNotifications)
        {
          description = "notify about nixos system updates";
          serviceConfig = {
            Type = "oneshot";
          };

          script = ''
            ${pkgs.libnotify}/bin/notify-send \
              --app-name="NixPull" \
              --urgency=normal \
              --icon=system-software-update \
              "System Update Available" \
              "Run 'nixpull pull' to update your system"
          '';
        };

    # client mode: apply updates service
    systemd.services.nixpull-apply = pkgs.lib.mkIf (cfg.mode == "client") {
      description = "apply nixos system update";
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };

      script = ''
        ${nixpullPackage}/bin/nixpull pull -a
      '';
    };

    # server mode: build timer
    systemd.timers.nixpull-build = pkgs.lib.mkIf (cfg.mode == "server" && cfg.autoBuild) {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.buildInterval;
        Persistent = true;
        RandomizedDelaySec = "5m";
      };
    };

    # server mode: build service
    systemd.services.nixpull-build =
      pkgs.lib.mkIf (cfg.mode == "server" && cfg.autoBuild && cfg.flake != "")
        {
          description = "build all nixos configurations for nixpull";
          serviceConfig = {
            Type = "oneshot";
            User = "root";
          };

          script = ''
            cd ${cfg.flake}
            ${nixpullPackage}/bin/nixpull build
          '';
        };
  };
}
