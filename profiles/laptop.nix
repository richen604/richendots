{ richenLib, pkgs, ... }:
{
  imports = [
    (import ../wrappers/mango/_session.nix {
      inherit pkgs richenLib;
      waybarPackage = richenLib.wrappers.waybar-laptop;
      swayidlePackage = richenLib.wrappers.swayidle-laptop;
    })
  ];

  #packages
  environment.systemPackages = [
    richenLib.wrappers.mango-laptop
    richenLib.wrappers.swaylock-laptop
    richenLib.wrappers.swayidle-laptop
    richenLib.wrappers.waybar-laptop
  ];

  boot.loader.grub = {
    gfxmodeEfi = "1920x1080";
  };

  # power management
  services.tlp.enable = true;
  powerManagement.enable = true;
  services.thermald.enable = true;
  services.upower.enable = true;

  # greetd configuration
  services.greetd.settings = rec {
    initial_session = {
      command = "${richenLib.wrappers.mango-laptop}/bin/mango";
      user = "richen";
    };
    default_session = initial_session;
  };

  # theme settings
  programs.dconf.profiles.user.databases = [
    {
      settings."org/gnome/desktop/interface".cursor-size = "48";
    }
  ];
  environment.variables.XCURSOR_SIZE = 48;

  hjem.users.richen.files.".config/mango/config.conf".source =
    pkgs.writeText "config.conf" richenLib.wrappers.mango-laptop.config.content;

  xdg.portal.configPackages = [
    richenLib.wrappers.mango-laptop
  ];

}
