{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.services.nixpull;

  configFile = pkgs.writeText "nixpull-config.json" (
    builtins.toJSON {
      role = cfg.role;
      flake = cfg.flake;
      stateRoot = "/var/lib/nixpull";
      build = {
        hosts = cfg.build.hosts;
        maxJobs = cfg.build.maxJobs;
        cores = cfg.build.cores;
        publishPartial = cfg.build.publishPartial;
      };
      server = cfg.server;
      fetch = cfg.fetch;
      activation = cfg.activation;
    }
  );

  notifyUsers = lib.concatStringsSep " " cfg.notify.users;

  nixpullPackage = pkgs.writeShellApplication {
    name = "nixpull";
    runtimeInputs = with pkgs; [
      bash
      coreutils
      diffutils
      findutils
      gnugrep
      gnused
      openssh
      nix
      nix-output-monitor
      jq
      dix
      git
      gum
    ];
    runtimeEnv.NIXPULL_CONFIG = configFile;
    text = builtins.readFile ./nixpull.sh;
  };

  nixpullNotifyPackage = pkgs.writeShellApplication {
    name = "nixpull-notify";
    runtimeInputs = with pkgs; [
      coreutils
      gnugrep
      jq
      libnotify
      sudo
      systemd
    ];
    runtimeEnv.NIXPULL_NOTIFY_USERS = notifyUsers;
    text = ''
      set -euo pipefail

      state=/var/lib/nixpull/client/state.json
      user=$(id -un)
      allowed=" $NIXPULL_NOTIFY_USERS "
      if [ -n "$NIXPULL_NOTIFY_USERS" ] && ! [[ "$allowed" == *" $user "* ]]; then
        exit 0
      fi

      [ -r "$state" ] || exit 0

      activatable=$(jq -r '.fetched.activatablePath // empty' "$state")
      toplevel=$(jq -r '.fetched.toplevelPath // empty' "$state")
      built_at=$(jq -r '.fetched.builtAt // "unknown"' "$state")
      branch=$(jq -r '.fetched.gitBranch // empty' "$state")
      rev=$(jq -r '.fetched.gitRev // empty' "$state")
      host=$(jq -r '.host // "unknown"' "$state")
      [ -n "$activatable" ] || exit 0

      current=$(readlink /run/current-system 2>/dev/null || true)
      if [ -n "$toplevel" ] && [ "$current" = "$toplevel" ]; then
        exit 0
      fi

      state_home=''${XDG_STATE_HOME:-$HOME/.local/state}/nixpull
      dismissed="$state_home/dismissed"
      if [ -f "$dismissed" ] && grep -Fxq "$activatable" "$dismissed"; then
        exit 0
      fi

      summary="NixOS update ready"
      printf -v body 'Host: %s\nBuilt: %s' "$host" "$built_at"
      if [ -n "$branch" ] || [ -n "$rev" ]; then
        short_rev=''${rev:0:8}
        printf -v body '%s\nSource: %s@%s' "$body" "''${branch:-unknown}" "''${short_rev:-unknown}"
      fi

      action=$(
        notify-send \
          --app-name=nixpull \
          --icon=software-update-available \
          --urgency=normal \
          --expire-time=0 \
          --hint=string:x-canonical-private-synchronous:nixpull-update \
          --action=apply=Apply \
          --action=dismiss=Dismiss \
          --wait \
          "$summary" \
          "$body" || true
      )

      case "$action" in
        apply)
          if sudo -n ${pkgs.systemd}/bin/systemctl start nixpull-apply.service; then
            notify-send --app-name=nixpull --icon=software-update-available "Applying NixOS update" "nixpull-apply.service started"
          else
            notify-send --app-name=nixpull --icon=dialog-error --urgency=critical "NixOS update failed" "Could not start nixpull-apply.service"
          fi
          ;;
        dismiss)
          mkdir -p "$state_home"
          printf '%s\n' "$activatable" >>"$dismissed"
          ;;
      esac
    '';
  };
in
{
  options.services.nixpull = {
    enable = lib.mkEnableOption "nixpull pull-based NixOS profile updates";

    role = lib.mkOption {
      type = lib.types.enum [
        "builder"
        "client"
      ];
      description = "Whether this host publishes builds or fetches published builds.";
    };

    flake = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/dev/richendots";
      description = "Flake path used by the builder to build deploy-rs activatable profiles.";
    };

    build = {
      hosts = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [
          "cedar"
          "fern"
          "oak"
        ];
        description = "NixOS hosts the builder publishes.";
      };

      maxJobs = lib.mkOption {
        type = lib.types.ints.positive;
        default = 1;
        description = "Maximum concurrent host profile builds launched by nixpull.";
      };

      cores = lib.mkOption {
        type = lib.types.nullOr lib.types.ints.positive;
        default = null;
        description = "Optional --cores value passed to each nix build.";
      };

      publishPartial = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Publish successful host builds even when other hosts fail.";
      };

      interval = lib.mkOption {
        type = lib.types.str;
        default = "hourly";
        example = "Mon *-*-* 03:00:00";
        description = "Builder timer schedule.";
      };
    };

    server = {
      host = lib.mkOption {
        type = lib.types.str;
        default = "localhost";
        description = "Host that publishes nixpull builder state.";
      };

      user = lib.mkOption {
        type = lib.types.str;
        default = "root";
        description = "SSH user for metadata access.";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 22;
        description = "SSH port for metadata access.";
      };

      sshOptions = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "-o"
          "BatchMode=yes"
          "-o"
          "ConnectTimeout=10"
        ];
        description = "Extra options passed to ssh for metadata access.";
      };

      store = lib.mkOption {
        type = lib.types.str;
        default = "ssh-ng://localhost";
        description = "Nix store URL used by clients for nix copy --from.";
      };
    };

    fetch = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable the client background fetch timer.";
      };

      interval = lib.mkOption {
        type = lib.types.str;
        default = "hourly";
        description = "Client fetch timer schedule.";
      };
    };

    activation = {
      autoApply = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable automatic client activation of fetched builds.";
      };

      interval = lib.mkOption {
        type = lib.types.str;
        default = "daily";
        description = "Client auto-activation timer schedule.";
      };

      goal = lib.mkOption {
        type = lib.types.enum [ "switch" ];
        default = "switch";
        description = "deploy-rs activation goal.";
      };

      magicRollback = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Use deploy-rs magic rollback during activation.";
      };

      autoRollback = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Use deploy-rs automatic rollback on activation failure.";
      };

      confirmTimeout = lib.mkOption {
        type = lib.types.ints.positive;
        default = 30;
        description = "deploy-rs confirmation timeout in seconds.";
      };

      activationTimeout = lib.mkOption {
        type = lib.types.ints.positive;
        default = 240;
        description = "deploy-rs activation timeout in seconds.";
      };

      tempPath = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/nixpull/deploy-rs";
        description = "deploy-rs temporary path used by magic rollback.";
      };
    };

    notify = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Notify GUI users when a fetched nixpull update is ready to apply.";
      };

      users = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "richen" ];
        description = "Users allowed to receive nixpull update notifications and start the apply service.";
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        assertions = [
          {
            assertion = cfg.role != "builder" || cfg.build.hosts != [ ];
            message = "services.nixpull.build.hosts must be set for builder role";
          }
          {
            assertion = inputs ? deploy-rs;
            message = "nixpull requires a deploy-rs flake input";
          }
        ];

        environment.systemPackages = [ nixpullPackage ];

        systemd.tmpfiles.rules = [
          "d /var/lib/nixpull 0755 root root -"
          "d /var/lib/nixpull/client 0755 root root -"
          "d ${toString cfg.activation.tempPath} 0755 root root -"
        ]
        ++ lib.optionals (cfg.role == "builder") [
          "d /var/lib/nixpull/builder 0755 ${cfg.server.user} root -"
          "Z /var/lib/nixpull/builder - ${cfg.server.user} root -"
        ];
      }

      (lib.mkIf (cfg.role == "builder") {
        systemd.timers.nixpull-build = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = cfg.build.interval;
            Persistent = true;
            RandomizedDelaySec = "5m";
          };
        };

        systemd.services.nixpull-build = {
          description = "Build deploy-rs activatable NixOS profiles for nixpull";
          serviceConfig = {
            Type = "oneshot";
            User = cfg.server.user;
            StateDirectory = "nixpull";
            WorkingDirectory = cfg.flake;
          };
          script = "${nixpullPackage}/bin/nixpull build";
        };
      })

      (lib.mkIf (cfg.role == "client") {
        systemd.timers.nixpull-fetch = lib.mkIf cfg.fetch.enable {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = cfg.fetch.interval;
            Persistent = true;
            RandomizedDelaySec = "5m";
          };
        };

        systemd.services.nixpull-fetch = lib.mkIf cfg.fetch.enable {
          description = "Fetch latest published nixpull profile";
          serviceConfig = {
            Type = "oneshot";
            User = "root";
            StateDirectory = "nixpull";
          };
          script = "${nixpullPackage}/bin/nixpull fetch";
        };

        systemd.timers.nixpull-apply = lib.mkIf cfg.activation.autoApply {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = cfg.activation.interval;
            Persistent = true;
            RandomizedDelaySec = "5m";
          };
        };

        systemd.services.nixpull-apply = {
          description = "Activate latest published nixpull profile";
          serviceConfig = {
            Type = "oneshot";
            User = "root";
            StateDirectory = "nixpull";
          };
          script = "${nixpullPackage}/bin/nixpull pull";
        };

        systemd.user.paths.nixpull-notify = lib.mkIf cfg.notify.enable {
          wantedBy = [ "default.target" ];
          pathConfig = {
            PathChanged = "/var/lib/nixpull/client/state.json";
            Unit = "nixpull-notify.service";
          };
        };

        systemd.user.services.nixpull-notify = lib.mkIf cfg.notify.enable {
          description = "Notify about fetched nixpull updates";
          wantedBy = [ "default.target" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${nixpullNotifyPackage}/bin/nixpull-notify";
          };
        };

        security.sudo.extraRules = lib.mkIf (cfg.notify.enable && cfg.notify.users != [ ]) [
          {
            users = cfg.notify.users;
            commands = [
              {
                command = "${pkgs.systemd}/bin/systemctl start nixpull-apply.service";
                options = [ "NOPASSWD" ];
              }
            ];
          }
        ];
      })
    ]
  );
}
