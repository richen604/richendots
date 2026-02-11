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

  nixpullPackage = pkgs.writeShellApplication {
    name = "nixpull";
    runtimeInputs = with pkgs; [
      coreutils
      openssh
      nix
      jq
      gum
      dix
    ];
    text = builtins.readFile ./nixpull.sh;
  };

in
{
  options.services.nixpull = {
    enable = pkgs.lib.mkEnableOption "nixpull system update service";

    user = pkgs.lib.mkOption {
      type = pkgs.lib.types.str;
      default = "richen";
      description = "User to run notifications and other user-level tasks as.";
    };

    mode = pkgs.lib.mkOption {
      type = pkgs.lib.types.enum [
        "server"
        "client"
      ];
      description = ''
        Operation mode:
        - server: Builds all configurations in the flake and stores their paths.
        - client: Fetches the latest build path from the server and applies it.
      '';
    };

    flake = pkgs.lib.mkOption {
      type = pkgs.lib.types.str;
      default = "";
      example = "/home/user/dots";
      description = "Path to the flake containing NixOS configurations (server mode only).";
    };

    storeDir = pkgs.lib.mkOption {
      type = pkgs.lib.types.str;
      default = "/tmp/nixpull";
      description = "Directory on the server where build paths are stored.";
    };

    # Client-specific options
    checkInterval = pkgs.lib.mkOption {
      type = pkgs.lib.types.str;
      default = "hourly";
      example = "Mon *-*-* 03:00:00";
      description = "How often to check for updates (client mode). Uses systemd.time format.";
    };

    enableNotifications = pkgs.lib.mkOption {
      type = pkgs.lib.types.bool;
      default = true;
      description = "Enable desktop notifications when updates are available (client mode only).";
    };

    # Server-specific options
    buildInterval = pkgs.lib.mkOption {
      type = pkgs.lib.types.str;
      default = "hourly";
      example = "daily";
      description = "How often to build configs (server mode). Uses systemd.time format.";
    };

    autoBuild = pkgs.lib.mkOption {
      type = pkgs.lib.types.bool;
      default = false;
      description = "Automatically build configs on schedule (server mode). If false, run 'nixpull build' manually.";
    };
  };

  config = pkgs.lib.mkIf cfg.enable (
    pkgs.lib.mkMerge [
      # Validate flake path in server mode
      (pkgs.lib.mkIf (cfg.mode == "server" && cfg.autoBuild) {
        assertions = [
          {
            assertion = cfg.flake != "";
            message = "services.nixpull.flake must be set when mode is 'server' and autoBuild is enabled";
          }
        ];
      })

      {
        environment.systemPackages = pkgs.lib.mkDefault [ nixpullPackage ];

        # client mode
        systemd.timers.nixpull-check = pkgs.lib.mkIf (cfg.mode == "client") {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = cfg.checkInterval;
            Persistent = true;
            RandomizedDelaySec = "5m";
          };
        };

        systemd.services.nixpull-check = pkgs.lib.mkIf (cfg.mode == "client") {
          description = "check for nixos system updates";
          serviceConfig = {
            Type = "oneshot";
            User = "root";
          };

          script = ''
            if ${nixpullPackage}/bin/nixpull check; then
              echo "update available. run 'nixpull pull' to apply."
              ${pkgs.lib.optionalString cfg.enableNotifications ''
                # trigger user notification service
                ${pkgs.systemd}/bin/systemctl --user -M ${cfg.user}@ start nixpull-notify.service
              ''}
            else
              echo "no updates available"
            fi
          '';
        };

        systemd.user.services.nixpull-notify =
          pkgs.lib.mkIf (cfg.mode == "client" && cfg.enableNotifications)
            {
              description = "notify about nixos system updates";
              serviceConfig.Type = "oneshot";
              script = ''
                ${pkgs.libnotify}/bin/notify-send \
                  --app-name="NixPull" \
                  --urgency=normal \
                  --icon=system-software-update \
                  --action="approve=Apply Update" \
                  --action="deny=Dismiss" \
                  "System Update Available" \
                  "A new system configuration is ready to install" | while read -r action; do
                    case "$action" in
                      approve)
                        ${pkgs.systemd}/bin/systemctl start nixpull-apply.service
                        ;;
                      deny)
                        ${pkgs.libnotify}/bin/notify-send \
                          --app-name="NixPull" \
                          --icon=dialog-information \
                          "Update Dismissed" \
                          "Run 'nixpull pull' manually when ready"
                        ;;
                    esac
                  done
              '';
            };

        systemd.services.nixpull-apply = pkgs.lib.mkIf (cfg.mode == "client") {
          description = "apply nixos system update";
          serviceConfig = {
            Type = "oneshot";
            User = "root";
          };
          script = "${nixpullPackage}/bin/nixpull pull -a";
        };

        # server mode
        systemd.timers.nixpull-build = pkgs.lib.mkIf (cfg.mode == "server" && cfg.autoBuild) {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = cfg.buildInterval;
            Persistent = true;
            RandomizedDelaySec = "5m";
          };
        };

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
      }
    ]
  );
}
