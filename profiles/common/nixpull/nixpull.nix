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
      flake = cfg.flake;
      stateRoot = "/var/lib/nixpull";
      build = {
        hosts = cfg.builder.hosts;
        maxJobs = cfg.builder.maxJobs;
        cores = cfg.builder.cores;
        publishPartial = cfg.builder.publishPartial;
      };
      server = cfg.server;
      fetch = cfg.fetch;
      activation = cfg.activation;
    }
  );

  nixpullPackage = pkgs.writeShellApplication {
    name = "nixpull";
    runtimeInputs = with pkgs; [
      bash
      coreutils
      diffutils
      findutils
      gnugrep
      gnused
      curl
      hostname
      nix
      nix-output-monitor
      jq
      dix
      git
      gum
      systemd
    ];
    runtimeEnv.NIXPULL_CONFIG = configFile;
    runtimeEnv.NIXPULL_HOSTNAME = "${pkgs.hostname}/bin/hostname";
    text = builtins.readFile ./nixpull.sh;
  };

  nixpullNotifyPackage = pkgs.writeShellApplication {
    name = "nixpull-notify";
    runtimeInputs = with pkgs; [
      coreutils
      gnugrep
      jq
      libnotify
      polkit
      systemd
    ];
    text = ''
      set -euo pipefail

      state=/var/lib/nixpull/client/state.json
      [ -r "$state" ] || exit 0
      state_home=''${XDG_STATE_HOME:-$HOME/.local/state}/nixpull
      dismissed="$state_home/dismissed"
      current=$(readlink /run/current-system 2>/dev/null || true)

      fetching_status=$(jq -r '.fetching.status // empty' "$state")
      fetching_activatable=$(jq -r '.fetching.metadata.activatablePath // empty' "$state")
      fetching_toplevel=$(jq -r '.fetching.metadata.toplevelPath // empty' "$state")
      if [ "$fetching_status" = fetching ] && [ -n "$fetching_activatable" ]; then
        current_fetched=$(jq -r '.fetched.activatablePath // empty' "$state")
        if [ "$current_fetched" != "$fetching_activatable" ] \
          && { [ ! -f "$dismissed" ] || ! grep -Fxq "$fetching_activatable" "$dismissed"; } \
          && { [ -z "$fetching_toplevel" ] || [ "$current" != "$fetching_toplevel" ]; }; then
          host=$(jq -r '.host // "unknown"' "$state")
          built_at=$(jq -r '.fetching.metadata.builtAt // "unknown"' "$state")
          notify-send \
            --app-name=nixpull \
            --icon=software-update-available \
            --expire-time=8000 \
            --hint=string:x-canonical-private-synchronous:nixpull-fetching \
            "NixOS build available" \
            "Host: $host\nBuilt: $built_at\nFetching closure..." || true
        fi
        exit 0
      fi

      if [ "$fetching_status" = failure ] && [ -n "$fetching_activatable" ]; then
        host=$(jq -r '.host // "unknown"' "$state")
        exit_code=$(jq -r '.fetching.exitCode // "unknown"' "$state")
        notify-send \
          --app-name=nixpull \
          --icon=dialog-error \
          --urgency=critical \
          --expire-time=12000 \
          --hint=string:x-canonical-private-synchronous:nixpull-fetching \
          "NixOS fetch failed" \
          "Host: $host\nExit code: $exit_code" || true
        exit 0
      fi

      activatable=$(jq -r '.fetched.activatablePath // empty' "$state")
      toplevel=$(jq -r '.fetched.toplevelPath // empty' "$state")
      [ -n "$activatable" ] || exit 0

      [ -n "$toplevel" ] && [ "$current" = "$toplevel" ] && exit 0

      if [ -f "$dismissed" ] && grep -Fxq "$activatable" "$dismissed"; then
        exit 0
      fi

      host=$(jq -r '.host // "unknown"' "$state")
      built_at=$(jq -r '.fetched.builtAt // "unknown"' "$state")
      action=$(notify-send \
        --app-name=nixpull \
        --icon=software-update-available \
        --expire-time=0 \
        --hint=string:x-canonical-private-synchronous:nixpull-update \
        --action=apply=Apply \
        --action=dismiss=Dismiss \
        --wait \
        "NixOS update ready" \
        "Host: $host\nBuilt: $built_at" || true)

      case "$action" in
        apply)
          if pkexec ${pkgs.systemd}/bin/systemctl start nixpull-apply.service; then
            notify-send --app-name=nixpull --icon=software-update-available \
              "Applying NixOS update" "nixpull-apply.service started"
          else
            notify-send --app-name=nixpull --icon=dialog-error --urgency=critical \
              "NixOS update failed" "Could not start nixpull-apply.service"
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

    flake = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/dev/richendots";
      description = "Flake path used by the builder to build deploy-rs activatable profiles.";
    };

    builder = {
      enable = lib.mkEnableOption "the nixpull builder";

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
      metadataUrl = lib.mkOption {
        type = lib.types.str;
        default = "http://localhost:5000/nixpull/state.json";
        description = "URL for published nixpull builder state.";
      };

      substituterUrl = lib.mkOption {
        type = lib.types.str;
        default = "http://localhost:5000";
        description = "Binary cache substituter URL used by clients for closure fetches.";
      };
    };

    client.enable = lib.mkEnableOption "the nixpull client" // { default = true; };

    notify.enable = lib.mkEnableOption "desktop notifications for fetched updates";

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

      randomizedDelaySec = lib.mkOption {
        type = lib.types.str;
        default = "30s";
        description = "Randomized delay added to the client fetch timer.";
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

  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        assertions = [
          {
            assertion = !cfg.builder.enable || cfg.builder.hosts != [ ];
            message = "services.nixpull.builder.hosts must be set when the builder is enabled";
          }
          {
            assertion = inputs ? deploy-rs;
            message = "nixpull requires a deploy-rs flake input";
          }
        ];

        environment.systemPackages = [ nixpullPackage ];

        systemd.tmpfiles.rules = [
          "d /var/lib/nixpull 0755 root root -"
          "d ${toString cfg.activation.tempPath} 0755 root root -"
        ]
        ++ lib.optionals cfg.client.enable [
          "d /var/lib/nixpull/client 0755 root root -"
          "f /var/lib/nixpull/client/log 0644 root root -"
          "Z /var/lib/nixpull/client 0755 root root -"
          "z /var/lib/nixpull/client/log 0644 root root -"
          "z /var/lib/nixpull/client/state.json 0644 root root -"
          "Z /var/lib/nixpull/client - root root -"
        ]
        ++ lib.optionals cfg.builder.enable [
          "d /var/lib/nixpull/builder 0755 root root -"
          "f /var/lib/nixpull/builder/log 0644 root root -"
          "Z /var/lib/nixpull/builder 0755 root root -"
          "z /var/lib/nixpull/builder/log 0644 root root -"
          "z /var/lib/nixpull/builder/state.json 0644 root root -"
          "Z /var/lib/nixpull/builder - root root -"
        ];
      }

      (lib.mkIf cfg.builder.enable {
        systemd.timers.nixpull-build = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = cfg.builder.interval;
            Persistent = true;
            RandomizedDelaySec = "5m";
          };
        };

        systemd.services.nixpull-build = {
          description = "Build deploy-rs activatable NixOS profiles for nixpull";
          serviceConfig = {
            Type = "oneshot";
            StateDirectory = "nixpull";
            WorkingDirectory = cfg.flake;
          };
          script = "${nixpullPackage}/bin/nixpull build";
        };
      })

      (lib.mkIf cfg.client.enable {
        systemd.timers.nixpull-fetch = lib.mkIf cfg.fetch.enable {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = cfg.fetch.interval;
            Persistent = true;
            RandomizedDelaySec = cfg.fetch.randomizedDelaySec;
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
          script = "${nixpullPackage}/bin/nixpull activate";
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
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${nixpullNotifyPackage}/bin/nixpull-notify";
          };
        };

      })
    ]
  );
}
