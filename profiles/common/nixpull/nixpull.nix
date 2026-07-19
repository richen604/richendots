{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.services.nixpull;
  webhookTokenFile = if cfg.fetch.webhook.tokenFile == null then "/dev/null" else toString cfg.fetch.webhook.tokenFile;

  configFile = pkgs.writeText "nixpull-config.json" (
    builtins.toJSON {
      flake = cfg.flake;
      stateRoot = "/var/lib/nixpull";
      build = {
        hosts = cfg.builder.hosts;
        maxJobs = cfg.builder.maxJobs;
        cores = cfg.builder.cores;
        publishPartial = cfg.builder.publishPartial;
        fetchWebhooks = cfg.builder.fetchWebhooks;
        signingKeyFile = cfg.builder.signingKeyFile;
      };
      server = cfg.server;
      fetch = cfg.fetch;
      activation = cfg.activation;
    }
  );

  gitConfig = pkgs.writeText "nixpull-gitconfig" ''
    [safe]
    	directory = ${cfg.flake}
  '';

  nixpullPackage = pkgs.writeShellApplication {
    name = "nixpull";
    runtimeInputs = with pkgs; [
      bash
      coreutils
      curl
      hostname
      nix
      nix-output-monitor
      jq
      dix
      git
      gum
      openssh
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
    ];
    text = ''
      set -euo pipefail

      state=/var/lib/nixpull/client/state.json
      [ -r "$state" ] || exit 0
      state_home=''${XDG_STATE_HOME:-$HOME/.local/state}/nixpull
      dismissed="$state_home/dismissed"
      current=$(readlink /run/current-system 2>/dev/null || true)

      notify_last_pull_result() {
        [ -r "$state" ] || return 1

        last_pull_status=$(jq -r '.lastPull.status // empty' "$state")
        last_pull_at=$(jq -r '.lastPull.at // empty' "$state")
        last_pull_path=$(jq -r '.lastPull.activatablePath // empty' "$state")
        last_pull_toplevel=$(jq -r '.lastPull.toplevelPath // empty' "$state")
        [ -n "$last_pull_at" ] && [ -n "$last_pull_path" ] || return 1

        notified="$state_home/notified-last-pull"
        notified_key="$last_pull_at $last_pull_status $last_pull_path"
        if [ -f "$notified" ] && grep -Fxq "$notified_key" "$notified"; then
          return 1
        fi

        host=$(jq -r '.host // "unknown"' "$state")
        if [ "$last_pull_status" = success ] && [ -n "$last_pull_toplevel" ] && [ "$(readlink /run/current-system 2>/dev/null || true)" = "$last_pull_toplevel" ]; then
          mkdir -p "$state_home"
          printf '%s\n' "$notified_key" >>"$notified"
          notify-send \
            --app-name=nixpull \
            --icon=software-update-available \
            --expire-time=8000 \
            --hint=string:x-canonical-private-synchronous:nixpull-apply \
            "NixOS update applied" \
            "Host: $host" || true
          return 0
        elif [ "$last_pull_status" = failure ]; then
          mkdir -p "$state_home"
          printf '%s\n' "$notified_key" >>"$notified"
          exit_code=$(jq -r '.lastPull.exitCode // "unknown"' "$state")
          notify-send \
            --app-name=nixpull \
            --icon=dialog-error \
            --urgency=critical \
            --expire-time=12000 \
            --hint=string:x-canonical-private-synchronous:nixpull-apply \
            "NixOS update failed" \
            "Host: $host\nExit code: $exit_code" || true
          return 0
        fi

        return 1
      }

      notify_apply_progress() {
        local host=$1 apply_pid=$2
        local start elapsed progress
        local total=${toString (cfg.activation.confirmTimeout + cfg.activation.activationTimeout)}

        start=$(date +%s)

        while kill -0 "$apply_pid" 2>/dev/null; do
          elapsed=$(($(date +%s) - start))
          progress=$((elapsed * 95 / total))
          [ "$progress" -ge 5 ] || progress=5
          [ "$progress" -le 95 ] || progress=95
          notify-send \
            --app-name=nixpull \
            --icon=software-update-available \
            --expire-time=0 \
            --hint=string:x-canonical-private-synchronous:nixpull-apply \
            --hint=int:value:"$progress" \
            "NixOS update applying" \
            "Host: $host\nElapsed: ''${elapsed}s / ~''${total}s" || true
          sleep 1
        done
      }

      notify_last_pull_result && exit 0

      fetching_status=$(jq -r '.fetching.status // empty' "$state")
      fetching_activatable=$(jq -r '.fetching.metadata.activatablePath // empty' "$state")
      if [ "$fetching_status" = failure ] && [ -n "$fetching_activatable" ]; then
        host=$(jq -r '.host // "unknown"' "$state")
        exit_code=$(jq -r '.fetching.exitCode // "unknown"' "$state")
        fetching_at=$(jq -r '.fetching.at // empty' "$state")
        notified="$state_home/notified-fetch-failure"
        notified_key="$fetching_at $exit_code $fetching_activatable"
        if [ -f "$notified" ] && grep -Fxq "$notified_key" "$notified"; then
          exit 0
        fi
        mkdir -p "$state_home"
        printf '%s\n' "$notified_key" >>"$notified"
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

      last_pull_status=$(jq -r '.lastPull.status // empty' "$state")
      last_pull_path=$(jq -r '.lastPull.activatablePath // empty' "$state")
      if [ "$last_pull_status" = success ] && [ "$last_pull_path" = "$activatable" ]; then
        exit 0
      fi

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
          host=$(jq -r '.host // "unknown"' "$state")
          ${pkgs.systemd}/bin/systemctl start nixpull-apply.service &
          apply_pid=$!
          notify_apply_progress "$host" "$apply_pid"
          if wait "$apply_pid"; then
            notify_last_pull_result || true
          elif ! notify_last_pull_result; then
            notify-send --app-name=nixpull --icon=dialog-error --urgency=critical \
              --hint=string:x-canonical-private-synchronous:nixpull-apply \
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

  nixpullWebhookPackage = pkgs.writeShellApplication {
    name = "nixpull-webhook";
    runtimeInputs = with pkgs; [
      coreutils
      systemd
    ];
    text = ''
      set -euo pipefail

      token_file=${lib.escapeShellArg webhookTokenFile}
      [ -r "$token_file" ] || exit 1
      expected=$(tr -d '\r\n' <"$token_file")

      status="401 Unauthorized"
      body="unauthorized"

      if IFS= read -r request_line; then
        request_line=''${request_line%$'\r'}
        method=''${request_line%% *}
        rest=''${request_line#* }
        path=''${rest%% *}
        authorization=""

        while IFS= read -r header; do
          header=''${header%$'\r'}
          [ -n "$header" ] || break
          case "$header" in
            [Aa]uthorization:*)
              authorization=''${header#*:}
              authorization=''${authorization# }
              ;;
          esac
        done

        if [ "$method" = POST ] && [ "$path" = /nixpull/fetch ] && [ "$authorization" = "Bearer $expected" ]; then
          if systemctl start --no-block nixpull-fetch.service; then
            status="202 Accepted"
            body="fetch started"
          else
            status="500 Internal Server Error"
            body="failed to start fetch"
          fi
        elif [ "$method" != POST ] || [ "$path" != /nixpull/fetch ]; then
          status="404 Not Found"
          body="not found"
        fi
      fi

      printf 'HTTP/1.1 %s\r\nContent-Type: text/plain\r\nContent-Length: %s\r\nConnection: close\r\n\r\n%s\n' \
        "$status" "$((''${#body} + 1))" "$body"
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

      signingKeyFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Secret Nix signing key used to sign built profiles before publishing.";
      };

      fetchWebhooks = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule {
          options = {
            url = lib.mkOption {
              type = lib.types.str;
              example = "http://fern:5051/nixpull/fetch";
              description = "Webhook URL called after this host's build is published.";
            };

            tokenFile = lib.mkOption {
              type = lib.types.str;
              description = "File containing the bearer token for this host's webhook.";
            };
          };
        });
        default = { };
        description = "Per-host client fetch webhooks called immediately after publishing.";
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

    notify.applyUser = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "alice";
      description = "Active local desktop user allowed to start nixpull-apply.service from notifications.";
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

      randomizedDelaySec = lib.mkOption {
        type = lib.types.str;
        default = "30s";
        description = "Randomized delay added to the client fetch timer.";
      };

      webhook = {
        enable = lib.mkEnableOption "a socket-activated webhook that starts nixpull-fetch.service";

        port = lib.mkOption {
          type = lib.types.port;
          default = 5051;
          description = "TCP port for the client fetch webhook listener.";
        };

        tokenFile = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "File containing the bearer token accepted by the client fetch webhook.";
        };

        openFirewallOnTailscale = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Open the fetch webhook port only on the tailscale0 firewall interface.";
        };
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
          {
            assertion = !cfg.fetch.webhook.enable || cfg.fetch.webhook.tokenFile != null;
            message = "services.nixpull.fetch.webhook.tokenFile must be set when the webhook is enabled";
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
          environment.GIT_CONFIG_GLOBAL = gitConfig;
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

        systemd.services.nixpull-fetch = lib.mkIf (cfg.fetch.enable || cfg.fetch.webhook.enable) {
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
          restartIfChanged = false;
          stopIfChanged = false;
          serviceConfig = {
            Type = "oneshot";
            User = "root";
            StateDirectory = "nixpull";
          };
          script = "${nixpullPackage}/bin/nixpull activate";
        };

        systemd.sockets.nixpull-webhook = lib.mkIf cfg.fetch.webhook.enable {
          wantedBy = [ "sockets.target" ];
          socketConfig = {
            ListenStream = cfg.fetch.webhook.port;
            Accept = true;
          };
        };

        systemd.services."nixpull-webhook@" = lib.mkIf cfg.fetch.webhook.enable {
          description = "Start nixpull fetch from an authenticated webhook";
          serviceConfig = {
            Type = "exec";
            StandardInput = "socket";
            StandardOutput = "socket";
            StandardError = "journal";
            ExecStart = "${nixpullWebhookPackage}/bin/nixpull-webhook";
          };
        };

        networking.firewall.interfaces.tailscale0.allowedTCPPorts = lib.mkIf (
          cfg.fetch.webhook.enable && cfg.fetch.webhook.openFirewallOnTailscale
        ) [ cfg.fetch.webhook.port ];

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

        security.polkit.extraConfig = lib.mkIf (cfg.notify.enable && cfg.notify.applyUser != null) ''
          polkit.addRule(function(action, subject) {
            if (action.id == "org.freedesktop.systemd1.manage-units"
                && action.lookup("unit") == "nixpull-apply.service"
                && action.lookup("verb") == "start"
                && subject.user == ${builtins.toJSON cfg.notify.applyUser}
                && subject.local
                && subject.active) {
              return polkit.Result.YES;
            }
          });
        '';

      })
    ]
  );
}
