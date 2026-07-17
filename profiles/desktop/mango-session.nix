{
  lib,
  richenLib,
  pkgs,
  ...
}:
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

  services.greetd.settings = rec {
    initial_session = {
      command = "${richenLib.wrappers.mango-fern}/bin/mango";
      user = "richen";
    };
    default_session = initial_session;
  };

  systemd.user.services.sunshine = {
    wantedBy = lib.mkForce [ "mango-session.target" ];
    partOf = lib.mkForce [ "mango-session.target" ];
    after = lib.mkForce [ "mango-session.target" ];
    wants = lib.mkForce [ ];
  };

  hjem.users.richen.files.".config/mango/config.conf".source =
    pkgs.writeText "config.conf" richenLib.wrappers.mango-fern.config.content;

  xdg.portal.configPackages = [
    richenLib.wrappers.mango-fern
  ];
}
