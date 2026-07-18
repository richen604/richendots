{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.services.mutagen;

  mkNullableOption =
    type: default: description:
    mkOption {
      type = types.nullOr type;
      inherit default description;
    };

  mkStringOption = default: description: mkNullableOption types.str default description;

  mkBoolOption = default: description: mkNullableOption types.bool default description;

  mkIntOption = default: description: mkNullableOption types.int default description;

  buildSyncArgs =
    name: value:
    [
      "sync"
      "create"
      "--name=${name}"
    ]
    ++ optionals (value.alpha != null) [ value.alpha ]
    ++ optionals (value.beta != null) [ value.beta ]
    ++ optionals (value.mode != null) [ "--mode=${value.mode}" ]
    ++ optionals (value.ignore != null) (map (i: "--ignore=${i}") value.ignore)
    ++ optionals (value.vcsIgnore != null && value.vcsIgnore) [ "--ignore-vcs" ]
    ++ optionals (value.permissions != null) (
      optionals (value.permissions.defaultFileMode != null) [
        "--default-file-mode=${value.permissions.defaultFileMode}"
      ]
      ++ optionals (value.permissions.defaultDirectoryMode != null) [
        "--default-directory-mode=${value.permissions.defaultDirectoryMode}"
      ]
      ++ optionals (value.permissions.defaultOwner != null) [
        "--default-owner=${value.permissions.defaultOwner}"
      ]
      ++ optionals (value.permissions.defaultGroup != null) [
        "--default-group=${value.permissions.defaultGroup}"
      ]
    )
    ++ optionals (value.symlink != null && value.symlink.mode != null) [
      "--symlink-mode=${value.symlink.mode}"
    ]
    ++ optionals (value.watch != null) (
      optionals (value.watch.mode != null) [
        "--watch-mode=${value.watch.mode}"
      ]
      ++ optionals (value.watch.pollingInterval != null) [
        "--watch-polling-interval=${toString value.watch.pollingInterval}"
      ]
    )
    ++ optionals (value.probeMode != null) [ "--probe-mode=${value.probeMode}" ]
    ++ optionals (value.scanMode != null) [ "--scan-mode=${value.scanMode}" ]
    ++ optionals (value.stageMode != null) [ "--stage-mode=${value.stageMode}" ]
    ++ optionals (value.maxEntryCount != null) [
      "--max-entry-count=${toString value.maxEntryCount}"
    ]
    ++ optionals (value.maxStagingFileSize != null) [
      "--max-staging-file-size=${value.maxStagingFileSize}"
    ];

  buildForwardArgs =
    name: value:
    [
      "forward"
      "create"
      "--name=${name}"
    ]
    ++ optionals (value.source != null) [ value.source ]
    ++ optionals (value.destination != null) [ value.destination ]
    ++ optionals (value.socket != null) (
      optionals (value.socket.overwriteMode != null) [
        "--socket-overwrite-mode=${value.socket.overwriteMode}"
      ]
      ++ optionals (value.socket.owner != null) [ "--socket-owner=${value.socket.owner}" ]
      ++ optionals (value.socket.group != null) [ "--socket-group=${value.socket.group}" ]
      ++ optionals (value.socket.permissionMode != null) [
        "--socket-permission-mode=${value.socket.permissionMode}"
      ]
    );

  generateSyncCommands = mapAttrsToList (
    name: value:
    optionals value.enable [
      "echo \"Creating sync session: ${name}\""
      "${pkgs.mutagen}/bin/mutagen ${concatStringsSep " " (buildSyncArgs name value)}"
    ]
  ) cfg.sync;

  generateForwardCommands = mapAttrsToList (
    name: value:
    optionals value.enable [
      "echo \"Creating forward session: ${name}\""
      "${pkgs.mutagen}/bin/mutagen ${concatStringsSep " " (buildForwardArgs name value)}"
    ]
  ) cfg.forward;

  allSyncCommands = flatten generateSyncCommands;
  allForwardCommands = flatten generateForwardCommands;
in
{
  options.services.mutagen = {
    enable = mkEnableOption "Mutagen file synchronization and forwarding";

    sync = mkOption {
      type = types.attrsOf (
        types.submodule (
          { name, ... }:
          {
            options = {
              enable = mkEnableOption "this Mutagen synchronization session";
              alpha = mkOption {
                type = types.str;
                description = "Path to the alpha endpoint.";
              };
              beta = mkOption {
                type = types.str;
                description = "Path to the beta endpoint.";
              };
              mode = mkStringOption "two-way-safe" "Synchronization mode (e.g., 'two-way-resolved', 'one-way-replica').";
              ignore = mkOption {
                type = types.nullOr (types.listOf types.str);
                default = [ ];
                description = "List of paths to ignore during synchronization.";
              };
              vcsIgnore = mkBoolOption false "Whether to ignore VCS directories (e.g., .git, .svn).";

              permissions = mkOption {
                type = types.nullOr (
                  types.submodule {
                    options = {
                      defaultFileMode = mkStringOption "0600" "Default file mode (octal string, e.g., '0644').";
                      defaultDirectoryMode = mkStringOption "0700" "Default directory mode (octal string, e.g., '0755').";
                      defaultOwner = mkStringOption null "Default owner for synchronized files/directories.";
                      defaultGroup = mkStringOption null "Default group for synchronized files/directories.";
                    };
                  }
                );
                default = { };
                description = "Permissions configuration for synchronized files/directories.";
              };

              symlink = mkOption {
                type = types.nullOr (
                  types.submodule {
                    options = {
                      mode = mkStringOption "portable" "Symbolic link synchronization mode ('ignore', 'portable', 'posix-raw').";
                    };
                  }
                );
                default = { };
                description = "Symbolic link synchronization configuration.";
              };

              watch = mkOption {
                type = types.nullOr (
                  types.submodule {
                    options = {
                      mode = mkStringOption "portable" "Filesystem watching mode ('portable', 'force-poll', 'no-watch').";
                      pollingInterval = mkIntOption 10 "Polling interval in seconds for poll-based watching.";
                    };
                  }
                );
                default = { };
                description = "Filesystem watching configuration.";
              };

              probeMode = mkStringOption "assume" "Filesystem probing mode ('assume', 'probe').";
              scanMode = mkStringOption "accelerated" "Filesystem scanning mode ('accelerated', 'full').";
              stageMode = mkStringOption "mutagen" "Filesystem staging mode ('mutagen', 'neighboring', 'internal').";
              maxEntryCount = mkIntOption 0 "Maximum number of entries (files, directories, symlinks) to synchronize. 0 means unlimited.";
              maxStagingFileSize = mkStringOption "0" "Maximum size of files to stage (e.g., '100MB'). 0 means unlimited.";
            };
          }
        )
      );
      description = "Mutagen synchronization sessions configuration.";
      default = { };
    };

    forward = mkOption {
      type = types.attrsOf (
        types.submodule (
          { name, ... }:
          {
            options = {
              enable = mkEnableOption "this Mutagen forwarding session";
              source = mkOption {
                type = types.str;
                description = "Source address/path for forwarding.";
              };
              destination = mkOption {
                type = types.str;
                description = "Destination address/path for forwarding.";
              };

              socket = mkOption {
                type = types.nullOr (
                  types.submodule {
                    options = {
                      overwriteMode = mkStringOption "leave" "Behavior when a conflicting filesystem entry exists ('leave', 'overwrite').";
                      owner = mkStringOption null "Owner for Unix domain sockets.";
                      group = mkStringOption null "Group for Unix domain sockets.";
                      permissionMode = mkStringOption "0660" "Permission mode for Unix domain sockets (octal string, e.g., '0660').";
                    };
                  }
                );
                default = { };
                description = "Socket configuration for forwarding sessions.";
              };
            };
          }
        )
      );
      description = "Mutagen forwarding sessions configuration.";
      default = { };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.mutagen ];

    systemd.user.services = {
      mutagen-daemon = {
        description = "Mutagen Daemon";
        wantedBy = [ "default.target" ];
        after = [
          "network.target"
        ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.mutagen}/bin/mutagen daemon start";
          RemainAfterExit = true;
          Restart = "on-failure";
          Environment = "MUTAGEN_SSH_PATH=${pkgs.openssh}/bin";
        };
      };

      mutagen-sessions = mkIf ((length allSyncCommands > 0) || (length allForwardCommands > 0)) {
        description = "Mutagen Sessions";
        wantedBy = [ "default.target" ];
        after = [
          "network-online.target"
          "mutagen-daemon.service"
        ];
        wants = [ "network-online.target" ];
        requires = [ "mutagen-daemon.service" ];
        partOf = [ "mutagen-daemon.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "mutagen-sessions-start" /* bash */ ''
            set -euo pipefail

            # wait for network
            echo "Waiting for network..."
            timeout=60
            while [ $timeout -gt 0 ]; do
              if ${pkgs.iproute2}/bin/ip route show default | ${pkgs.gnugrep}/bin/grep -q .; then
                echo "Network is up"
                break
              fi
              sleep 1
              timeout=$((timeout - 1))
            done

            # wait for the mutagen daemon
            echo "Waiting for Mutagen daemon to be ready..."
            timeout=30
            while [ $timeout -gt 0 ]; do
              if ${pkgs.mutagen}/bin/mutagen sync list >/dev/null 2>&1; then
                echo "Mutagen daemon is ready"
                break
              fi
              sleep 1
              timeout=$((timeout - 1))
            done

            if [ $timeout -eq 0 ]; then
              echo "Error: Mutagen daemon failed to come online within 30 seconds"
              exit 1
            fi

            # restart sessions from config so stale syncs do not stick around.
            echo "Terminating all existing sync sessions..."
            ${pkgs.mutagen}/bin/mutagen sync terminate -a || true

            echo "Terminating all existing forward sessions..."
            ${pkgs.mutagen}/bin/mutagen forward terminate -a || true

            # todo: terminate mutagen projects here once mutagen supports it.
            # ${pkgs.mutagen}/bin/mutagen project terminate -a

            ${concatStringsSep "\n" allSyncCommands}

            ${concatStringsSep "\n" allForwardCommands}

            echo "All mutagen sessions have been created successfully"
          '';
          ExecStop = pkgs.writeShellScript "mutagen-sessions-stop" ''
            echo "Terminating all sync sessions..."
            ${pkgs.mutagen}/bin/mutagen sync terminate -a || true

            echo "Terminating all forward sessions..."
            ${pkgs.mutagen}/bin/mutagen forward terminate -a || true

            # todo: terminate mutagen projects here once mutagen supports it.
            # ${pkgs.mutagen}/bin/mutagen project terminate -a

            echo "All mutagen sessions have been terminated"
          '';
          Environment = "MUTAGEN_SSH_PATH=${pkgs.openssh}/bin";
        };
      };
    };
  };
}
