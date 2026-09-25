packages:
{
  config,
  inputs,
  lib,
  ...
}:

let
  cfg = config.services.nixpull;
  inherit (packages)
    gitConfig
    nixpullPackage
    nixpullNotifyPackage
    nixpullWebhookPackage
    ;
in
{
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
          {
            assertion =
              !cfg.builder.enable
              || !cfg.builder.fetchWebhook.enable
              || lib.all (urls: urls == [ ]) (lib.attrValues cfg.builder.fetchWebhook.urls)
              || cfg.builder.fetchWebhook.tokenFile != null;
            message = "services.nixpull.builder.fetchWebhook.tokenFile must be set when builder webhook URLs are configured";
          }
          {
            assertion = lib.all (urls: lib.all (url: lib.hasPrefix "https://" url) urls) (
              lib.attrValues cfg.builder.fetchWebhook.urls
            );
            message = "services.nixpull.builder.fetchWebhook.urls must contain only HTTPS URLs";
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
        security.sudo.extraRules = lib.mkIf (cfg.builder.triggerUsers != [ ]) [
          {
            users = cfg.builder.triggerUsers;
            commands = [
              {
                command = "/run/current-system/sw/bin/nixpull build";
                options = [ "NOPASSWD" ];
              }
            ];
          }
        ];

        systemd.timers.nixpull-build = lib.mkIf (cfg.builder.interval != null) {
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
          script = ''
            export PATH="/run/current-system/sw/bin:/run/current-system/sw/sbin:$PATH"
            ${cfg.builder.preBuild}
            ${nixpullPackage}/bin/nixpull build
          '';
        };

        systemd.services."nixpull-webhook-delivery@" = lib.mkIf cfg.builder.fetchWebhook.enable {
          description = "Deliver nixpull fetch webhook to %i";
          serviceConfig = {
            Type = "oneshot";
            User = "root";
            StateDirectory = "nixpull";
            ExecStart = "${nixpullPackage}/bin/nixpull deliver-webhook %i";
            TimeoutStartSec = "30s";
          };
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
          unitConfig = lib.optionalAttrs cfg.activation.autoApply {
            OnSuccess = "nixpull-apply.service";
          };
          serviceConfig = {
            Type = "oneshot";
            User = "root";
            StateDirectory = "nixpull";
          };
          script = "${nixpullPackage}/bin/nixpull fetch";
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

        systemd.services.nixpull-pull = {
          description = "Fetch and activate latest published nixpull profile";
          restartIfChanged = false;
          stopIfChanged = false;
          serviceConfig = {
            Type = "oneshot";
            User = "root";
            StateDirectory = "nixpull";
          };
          script = "${nixpullPackage}/bin/nixpull pull";
        };

        systemd.sockets.nixpull-webhook = lib.mkIf cfg.fetch.webhook.enable {
          wantedBy = [ "sockets.target" ];
          restartTriggers = [
            (builtins.toJSON {
              inherit (cfg.fetch.webhook) listenAddress port;
            })
          ];
          socketConfig = {
            ListenStream = "${cfg.fetch.webhook.listenAddress}:${toString cfg.fetch.webhook.port}";
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
