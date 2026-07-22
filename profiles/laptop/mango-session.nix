{ richenLib, pkgs, ... }:
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

  hjem.users.richen.files.".config/mango/config.conf".source =
    pkgs.writeText "config.conf" richenLib.wrappers.mango-oak.config.content;

  xdg.portal.configPackages = [
    richenLib.wrappers.mango-oak
  ];
}
