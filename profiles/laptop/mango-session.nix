{ richenLib, pkgs, ... }:
{
  imports = [
    (import ../../wrappers/mango/_session.nix {
      inherit pkgs richenLib;
      waybarPackage = richenLib.wrappers.waybar-laptop;
      swayidlePackage = richenLib.wrappers.swayidle-laptop;
    })
  ];

  environment.systemPackages = [
    richenLib.wrappers.mango-laptop
    richenLib.wrappers.swaylock-laptop
    richenLib.wrappers.swayidle-laptop
    richenLib.wrappers.waybar-laptop
  ];

  services.greetd.settings = rec {
    initial_session = {
      command = "${richenLib.wrappers.mango-laptop}/bin/mango";
      user = "richen";
    };
    default_session = initial_session;
  };

  hjem.users.richen.files.".config/mango/config.conf".source =
    pkgs.writeText "config.conf" richenLib.wrappers.mango-laptop.config.content;

  xdg.portal.configPackages = [
    richenLib.wrappers.mango-laptop
  ];
}
