{
  config,
  pkgs,
  lib,
}:

let
  cfg = config.services.nixpull;
  webhookTokenFile =
    if cfg.fetch.webhook.tokenFile == null then "/dev/null" else toString cfg.fetch.webhook.tokenFile;

  configFile = pkgs.writeText "nixpull-config.json" (
    builtins.toJSON {
      inherit (cfg) flake;
      inherit (cfg) remoteBuilder;
      stateRoot = "/var/lib/nixpull";
      build = {
        hosts = cfg.builder.hosts;
        maxJobs = cfg.builder.maxJobs;
        cores = cfg.builder.cores;
        publishPartial = cfg.builder.publishPartial;
        fetchWebhook = cfg.builder.fetchWebhook;
        signingKeyFile = cfg.builder.signingKeyFile;
      };
      inherit (cfg) server;
      inherit (cfg) fetch;
      inherit (cfg) activation;
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
      util-linux
      nix
      nix-output-monitor
      jq
      dix
      git
      gum
      openssh
      systemd
      time
    ];
    runtimeEnv.NIXPULL_CONFIG = configFile;
    runtimeEnv.NIXPULL_HOSTNAME = "${pkgs.hostname}/bin/hostname";
    runtimeEnv.GIT_CONFIG_GLOBAL = gitConfig;
    text = lib.concatMapStringsSep "\n" builtins.readFile [
      ./shell/shared.sh
      ./shell/output.sh
      ./shell/build.sh
      ./shell/client.sh
      ./shell/dispatcher.sh
    ];
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
      auto_apply=${lib.boolToString cfg.activation.autoApply}

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
        if [ "$last_pull_status" = activating ]; then
          mkdir -p "$state_home"
          printf '%s\n' "$notified_key" >>"$notified"
          notify-send \
            --app-name=nixpull \
            --icon=software-update-available \
            --expire-time=0 \
            --hint=string:x-canonical-private-synchronous:nixpull-apply \
            "NixOS update applying" \
            "Host: $host" || true
          return 0
        elif [ "$last_pull_status" = success ] && [ -n "$last_pull_toplevel" ] && [ "$(readlink /run/current-system 2>/dev/null || true)" = "$last_pull_toplevel" ]; then
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
      if [ "$fetching_status" = fetching ] && [ -n "$fetching_activatable" ]; then
        host=$(jq -r '.host // "unknown"' "$state")
        fetching_at=$(jq -r '.fetching.at // empty' "$state")
        notified="$state_home/notified-fetching"
        notified_key="$fetching_at $fetching_activatable"
        if [ -f "$notified" ] && grep -Fxq "$notified_key" "$notified"; then
          exit 0
        fi
        mkdir -p "$state_home"
        printf '%s\n' "$notified_key" >>"$notified"
        notify-send \
          --app-name=nixpull \
          --icon=software-update-available \
          --expire-time=0 \
          --hint=string:x-canonical-private-synchronous:nixpull-fetching \
          "NixOS update fetching" \
          "Host: $host" || true
        exit 0
      elif [ "$fetching_status" = failure ] && [ -n "$fetching_activatable" ]; then
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

      [ "$auto_apply" = true ] && exit 0

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
  inherit
    configFile
    gitConfig
    nixpullPackage
    nixpullNotifyPackage
    nixpullWebhookPackage
    ;
}
