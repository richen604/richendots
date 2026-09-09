{
  lib,
  pkgs,
  richenLib,
  ...
}:
let
  port = 16432;
  documentUrl = "http://127.0.0.1:${toString port}/";
  manifestUrl = "${documentUrl}manifest.json";
  cinnyTheme = import ./_theme.nix { inherit (richenLib) theme; };
  themeCss = pkgs.replaceVars ./system24-grove.css cinnyTheme.replacements;
  cinnyConfig = pkgs.writeText "cinny-config.json" (
    builtins.toJSON {
      defaultHomeserver = 0;
      homeserverList = [ "matrix.org" ];
      allowCustomHomeservers = false;
      featuredCommunities = {
        openAsDefault = false;
        spaces = [ ];
        rooms = [ ];
        servers = [ "matrix.org" ];
      };
    }
  );
  stylesheetMarker = ''<link rel="stylesheet" href="/system24-grove.css" data-richendots-theme="system24" />'';
  customizedFrontend =
    pkgs.runCommand "cinny-unwrapped-richendots"
      {
        inherit (pkgs.cinny-unwrapped) version meta;
      }
      ''
        cp -r ${pkgs.cinny-unwrapped} "$out"
        chmod -R u+w "$out"

        install -m 0644 ${themeCss} "$out/system24-grove.css"
        substituteInPlace "$out/index.html" \
          --replace-fail '</head>' '${stylesheetMarker}</head>'
        install -m 0644 ${cinnyConfig} "$out/config.json"

        test -s "$out/system24-grove.css"
        test "$(grep -oF '${stylesheetMarker}' "$out/index.html" | wc -l)" -eq 1
        grep -qF -- '--cinny-system24-marker: richendots' "$out/system24-grove.css"
        grep -qF -- '--oq6d070: var(--cinny-bg)' "$out/system24-grove.css"
        grep -RqF -- '--oq6d070:' "$out/assets"
        cmp ${cinnyConfig} "$out/config.json"
        test -s "$out/manifest.json"
      '';
  ensureCinnyPwa = pkgs.writeShellApplication {
    name = "ensure-cinny-pwa";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.curl
      pkgs.jq
      richenLib.wrappers.glide
    ];
    text = builtins.readFile ./ensure-pwa.sh;
  };
  cinnyTrayAction = pkgs.writeShellApplication {
    name = "cinny-tray-action";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
      pkgs.wlrctl
      richenLib.wrappers.glide
    ];
    text = builtins.readFile ./tray-action.sh;
  };
  cinnyTrayDispatch = pkgs.writeShellApplication {
    name = "cinny-tray-dispatch";
    text = ''
      case "$1" in
        show|hide|quit)
          exec ${lib.getExe cinnyTrayAction} "$1" ${manifestUrl}
          ;;
        *)
          exit 2
          ;;
      esac
    '';
  };
  cinnyTray = pkgs.writeShellApplication {
    name = "cinny-tray";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
      pkgs.systrayhelper
      cinnyTrayDispatch
    ];
    text = builtins.readFile ./systray.sh;
  };
  cinnyServer = pkgs.writeShellApplication {
    name = "cinny-server";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.static-web-server
    ];
    text = builtins.readFile ./serve.sh;
  };
in
{
  environment.systemPackages = [ cinnyTrayAction ];

  systemd.user.services.cinny-web = {
    description = "Cinny local web app";
    wantedBy = [ "mango-session.target" ];
    partOf = [ "mango-session.target" ];
    after = [ "graphical-session.target" ];
    startLimitIntervalSec = 60;
    startLimitBurst = 5;
    serviceConfig = {
      ExecStart = "${lib.getExe cinnyServer} ${customizedFrontend} ${toString port}";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };

  systemd.user.services.cinny-pwa-install = {
    description = "Install Cinny as a Glide PWA";
    wantedBy = [ "mango-session.target" ];
    partOf = [ "mango-session.target" ];
    requires = [ "cinny-web.service" ];
    after = [ "cinny-web.service" ];
    startLimitIntervalSec = 60;
    startLimitBurst = 5;
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${lib.getExe ensureCinnyPwa} ${manifestUrl} ${documentUrl}";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  systemd.user.services.cinny = {
    description = "Cinny Glide PWA";
    partOf = [ "mango-session.target" ];
    requires = [ "cinny-pwa-install.service" ];
    after = [ "cinny-pwa-install.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${lib.getExe cinnyTrayAction} show ${manifestUrl}";
      RemainAfterExit = true;
    };
  };

  systemd.user.services.cinny-tray = {
    description = "Cinny tray menu";
    wantedBy = [ "mango-session.target" ];
    partOf = [ "mango-session.target" ];
    requires = [ "cinny-pwa-install.service" ];
    after = [ "cinny-pwa-install.service" ];
    startLimitIntervalSec = 60;
    startLimitBurst = 5;
    serviceConfig = {
      ExecStart = "${lib.getExe cinnyTray} ${customizedFrontend}/public/android/android-chrome-48x48.png";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };
}
