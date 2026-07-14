{
  lib,
  richenLib,
  pkgs,
  ...
}:
{
  imports = [
    (import ../wrappers/mango/_session.nix {
      inherit pkgs richenLib;
      waybarPackage = richenLib.wrappers.waybar;
      swayidlePackage = richenLib.wrappers.swayidle;
      extraWantedServices = [ "sunshine.service" ];
    })
  ];

  #packages
  environment.systemPackages = [
    richenLib.wrappers.mango
    richenLib.wrappers.swaylock
    richenLib.wrappers.swayidle
    richenLib.wrappers.waybar
  ];

  # greetd configuration
  services.greetd.settings = rec {
    initial_session = {
      command = "${richenLib.wrappers.mango}/bin/mango";
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

  # theme settings
  programs.dconf.profiles.user.databases = [
    {
      settings."org/gnome/desktop/interface".cursor-size = "24";
    }
  ];
  environment.variables.XCURSOR_SIZE = "24";

  hjem.users.richen.files.".config/mango/config.conf".source =
    pkgs.writeText "config.conf" richenLib.wrappers.mango.config.content;

  xdg.portal.configPackages = [
    richenLib.wrappers.mango
  ];

}
