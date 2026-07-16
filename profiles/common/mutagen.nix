{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.services.mutagen;

  # Helper function to create common option types
  mkNullableOption =
    type: default: description:
    mkOption {
      type = types.nullOr type;
      inherit default description;
    };

  # Helper function to create string option with default
  mkStringOption = default: description: mkNullableOption types.str default description;

  # Helper function to create boolean option with default
  mkBoolOption = default: description: mkNullableOption types.bool default description;

  # Helper function to create int option with default
  mkIntOption = default: description: mkNullableOption types.int default description;

  # Helper function to build command arguments for sync sessions
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
    # Permissions options
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
    # Symlink options
    ++ optionals (value.symlink != null && value.symlink.mode != null) [
      "--symlink-mode=${value.symlink.mode}"
    ]
    # Watch options
    ++ optionals (value.watch != null) (
      optionals (value.watch.mode != null) [
        "--watch-mode=${value.watch.mode}"
      ]
      ++ optionals (value.watch.pollingInterval != null) [
        "--watch-polling-interval=${toString value.watch.pollingInterval}"
      ]
    )
    # Other options
    ++ optionals (value.probeMode != null) [ "--probe-mode=${value.probeMode}" ]
    ++ optionals (value.scanMode != null) [ "--scan-mode=${value.scanMode}" ]
    ++ optionals (value.stageMode != null) [ "--stage-mode=${value.stageMode}" ]
    ++ optionals (value.maxEntryCount != null) [
      "--max-entry-count=${toString value.maxEntryCount}"
    ]
    ++ optionals (value.maxStagingFileSize != null) [
      "--max-staging-file-size=${value.maxStagingFileSize}"
    ];

  # Helper function to build command arguments for forward sessions
  buildForwardArgs =
    name: value:
    [
      "forward"
      "create"
      "--name=${name}"
    ]
    ++ optionals (value.source != null) [ value.source ]
    ++ optionals (value.destination != null) [ value.destination ]
    # Socket options
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

  # Helper function to generate all sync session creation commands
  generateSyncCommands = mapAttrsToList (
    name: value:
    optionals value.enable [
      "echo \"Creating sync session: ${name}\""
      "${pkgs.mutagen}/bin/mutagen ${concatStringsSep " " (buildSyncArgs name value)}"
    ]
  ) cfg.sync;

  # Helper function to generate all forward session creation commands
  generateForwardCommands = mapAttrsToList (
    name: value:
    optionals value.enable [
      "echo \"Creating forward session: ${name}\""
      "${pkgs.mutagen}/bin/mutagen ${concatStringsSep " " (buildForwardArgs name value)}"
    ]
  ) cfg.forward;

  # Flatten the command lists
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
              # Sync behavior options
              mode = mkStringOption "two-way-safe" "Synchronization mode (e.g., 'two-way-resolved', 'one-way-replica').";
              ignore = mkOption {
                type = types.nullOr (types.listOf types.str);
                default = [ ];
                description = "List of paths to ignore during synchronization.";
              };
              vcsIgnore = mkBoolOption false "Whether to ignore VCS directories (e.g., .git, .svn).";

              # File permission options
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

              # Symlink handling options
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

              # Filesystem watching options
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

              # Advanced sync options
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

              # Socket options for Unix domain sockets
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
    # Add mutagen to system packages so it's available for manual use
    environment.systemPackages = [ pkgs.mutagen ];

    # Set up systemd services
    systemd.user.services = {
      # Main daemon service
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

      # Single consolidated service for all mutagen sessions
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

            # Wait for network connectivity
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

            # Wait for daemon to be ready
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

            # Terminate all existing sessions to start fresh
            echo "Terminating all existing sync sessions..."
            ${pkgs.mutagen}/bin/mutagen sync terminate -a || true

            echo "Terminating all existing forward sessions..."
            ${pkgs.mutagen}/bin/mutagen forward terminate -a || true

            # TODO: Add support for terminating all mutagen projects when the feature becomes available
            # ${pkgs.mutagen}/bin/mutagen project terminate -a

            # Create all configured sync sessions
            ${concatStringsSep "\n" allSyncCommands}

            # Create all configured forward sessions
            ${concatStringsSep "\n" allForwardCommands}

            echo "All mutagen sessions have been created successfully"
          '';
          ExecStop = pkgs.writeShellScript "mutagen-sessions-stop" ''
            echo "Terminating all sync sessions..."
            ${pkgs.mutagen}/bin/mutagen sync terminate -a || true

            echo "Terminating all forward sessions..."
            ${pkgs.mutagen}/bin/mutagen forward terminate -a || true

            # TODO: Add support for terminating all mutagen projects when the feature becomes available
            # ${pkgs.mutagen}/bin/mutagen project terminate -a

            echo "All mutagen sessions have been terminated"
          '';
          Environment = "MUTAGEN_SSH_PATH=${pkgs.openssh}/bin";
        };
      };
    };
  };
}
