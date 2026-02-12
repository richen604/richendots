{ richenLib, pkgs, ... }:
{

  #packages
  environment.systemPackages = [
    richenLib.wrappers.mango
    richenLib.wrappers.swaylock
    richenLib.wrappers.swayidle
  ];

  # greetd configuration
  services.greetd.settings = rec {
    initial_session = {
      command = "${richenLib.wrappers.mango}/bin/mango";
      user = "richen";
    };
    default_session = initial_session;
  };

  # theme settings
  programs.dconf.profiles.user.databases = [
    {
      settings."org/gnome/desktop/interface".cursor-size = "24";
    }
  ];
  environment.variables.XCURSOR_SIZE = "24";

  hjem.users.richen.files.".config/mango/config.conf".source =
    pkgs.writeText "config.conf" richenLib.wrappers.mango.passthru.config;

}
