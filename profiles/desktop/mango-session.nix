{
  config,
  lib,
  richenLib,
  pkgs,
  ...
}:
let
  mangoConfig = pkgs.writeText "config.conf" richenLib.wrappers.mango-fern.config.content;
  mangoReloadConfig = pkgs.writeShellScript "mango-reload-config" ''
    ${richenLib.wrappers.mango-fern}/bin/mmsg dispatch reload_config || true
  '';
in
{
  imports = [
    (import ../../wrappers/mango/_session.nix {
      inherit pkgs richenLib;
      mangoPackage = richenLib.wrappers.mango-fern;
      waybarPackage = richenLib.wrappers.waybar;
      swayidlePackage = richenLib.wrappers.swayidle;
      extraWantedServices = [ "sunshine.service" ];
    })
  ];

  environment.systemPackages = [
    richenLib.wrappers.mango-fern
    richenLib.wrappers.swaylock
    richenLib.wrappers.swayidle
    richenLib.wrappers.waybar
  ];

  systemd.user.services.sunshine = {
    wantedBy = lib.mkForce [ "mango-session.target" ];
    partOf = lib.mkForce [ "graphical-session.target" ];
    after = lib.mkForce [ "graphical-session.target" ];
    wants = lib.mkForce [ ];
  };

  hjem.users.richen = {
    files.".config/mango/config.conf".source = mangoConfig;

    systemd.services.mango-reload-config = {
      description = "Reload Mango config";
      wantedBy = [ "mango-session.target" ];
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = mangoReloadConfig;
      };
      restartTriggers = [ config.hjem.users.richen.files.".config/mango/config.conf".source ];
    };
  };

  xdg.portal.configPackages = [
    richenLib.wrappers.mango-fern
  ];
}
