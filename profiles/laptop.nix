{ richenLib, pkgs, ... }:
{

  #packages
  environment.systemPackages = [
    richenLib.wrappers.mango-laptop
  ];

  boot.loader.grub = {
    gfxmodeEfi = "1920x1080";
  };

  # power management
  services.tlp.enable = true;
  powerManagement.enable = true;
  services.thermald.enable = true;

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
    pkgs.writeText "config.conf" richenLib.wrappers.mango-laptop.passthru.config;

}
