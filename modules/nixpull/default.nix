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
      jq
      dix
      git
    ];
    runtimeEnv.NIXPULL_CONFIG = configFile;
    text = builtins.readFile ./nixpull.sh;
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
        default = "cedar.build";
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
        default = "ssh-ng://cedar.build";
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
        type = lib.types.enum [
          "switch"
          "boot"
          "test"
          "dry-activate"
        ];
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
          "d /var/lib/nixpull/builder 0755 root root -"
          "d /var/lib/nixpull/client 0755 root root -"
          "d ${toString cfg.activation.tempPath} 0755 root root -"
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
            User = "root";
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

        systemd.services.nixpull-apply = lib.mkIf cfg.activation.autoApply {
          description = "Activate latest published nixpull profile";
          serviceConfig = {
            Type = "oneshot";
            User = "root";
            StateDirectory = "nixpull";
          };
          script = "${nixpullPackage}/bin/nixpull pull";
        };
      })
    ]
  );
}
