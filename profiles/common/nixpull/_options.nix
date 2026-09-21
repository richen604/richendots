{ lib }:
{
  enable = lib.mkEnableOption "nixpull pull-based NixOS profile updates";

  flake = lib.mkOption {
    type = lib.types.str;
    default = "/mnt/dev/richendots";
    description = "Flake path used by the builder to build deploy-rs activatable profiles.";
  };

  builder = {
    enable = lib.mkEnableOption "the nixpull builder";

    triggerUsers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "alice" ];
      description = "Users allowed to trigger the local nixpull builder without interactive sudo authentication.";
    };

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
      description = "Maximum concurrent Nix derivations allowed in each host build.";
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

    preBuild = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Shell commands run from the flake directory before each builder run.";
    };

    signingKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Secret Nix signing key used to sign built profiles before publishing.";
    };

    fetchWebhook = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Notify configured host fetch webhooks after publication.";
      };

      urls = lib.mkOption {
        type = lib.types.attrsOf (lib.types.listOf lib.types.str);
        default = { };
        example.fern = [ "https://updates.example.test/nixpull/fetch" ];
        description = "Ordered HTTPS fetch webhook URLs keyed by host. Hosts without URLs use polling only.";
      };

      tokenFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Shared bearer-token file used to authenticate client fetch webhooks.";
      };

      retries = lib.mkOption {
        type = lib.types.ints.positive;
        default = 2;
        description = "Attempts made against each configured webhook URL.";
      };

      attemptTimeoutSec = lib.mkOption {
        type = lib.types.ints.positive;
        default = 4;
        description = "Maximum duration of each webhook delivery attempt.";
      };
    };

    interval = lib.mkOption {
      type = lib.types.str;
      default = "hourly";
      example = "Mon *-*-* 03:00:00";
      description = "Builder timer schedule.";
    };
  };

  remoteBuilder = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    example = "cedar";
    description = "SSH host used by nixpull build when this machine is only a build trigger client.";
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
      example = "ssh-ng://builder.example";
      description = "Nix store URL used by clients for closure fetches; supports HTTPS caches, ssh-ng stores, and other nix copy sources.";
    };
  };

  client.enable = lib.mkEnableOption "the nixpull client" // {
    default = true;
  };

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
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable a socket-activated webhook that starts nixpull-fetch.service.";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 5051;
        description = "TCP port for the client fetch webhook listener.";
      };

      listenAddress = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = "Address on which the client fetch webhook socket listens.";
      };

      tokenFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "File containing the bearer token accepted by the client fetch webhook.";
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

}
