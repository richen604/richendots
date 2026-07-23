{
  config,
  richenLib,
  pkgs,
  ...
}:
let
  mangoConfig = pkgs.writeText "config.conf" richenLib.wrappers.mango-oak.config.content;
  mangoReloadConfig = pkgs.writeShellScript "mango-reload-config" ''
    ${richenLib.wrappers.mango-oak}/bin/mmsg dispatch reload_config || true
  '';
in
{
  imports = [
    (import ../../wrappers/mango/_session.nix {
      inherit pkgs richenLib;
      mangoPackage = richenLib.wrappers.mango-oak;
      waybarPackage = richenLib.wrappers.waybar-laptop;
      swayidlePackage = richenLib.wrappers.swayidle-laptop;
      vicinaePackage = richenLib.wrappers.vicinae-laptop;
    })
  ];

  environment.systemPackages = [
    richenLib.wrappers.mango-oak
    richenLib.wrappers.swaylock-laptop
    richenLib.wrappers.swayidle-laptop
    richenLib.wrappers.waybar-laptop
  ];

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
    richenLib.wrappers.mango-oak
  ];
}
