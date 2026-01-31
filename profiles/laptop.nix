{ richenLib, pkgs, ... }:
{

  #packages
  environment.systemPackages = [
    richenLib.wrappers.mango-laptop
  ];

  environment.etc."mango/config.conf".source =
    pkgs.writeText "config.conf" richenLib.wrappers.mango-laptop.passthru.config;

  boot.loader.grub = {
    gfxmodeEfi = "1024x768";
  };

  # greetd configuration
  services.greetd.settings = {
    default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --sessions ${richenLib.wrappers.mango-laptop}/share/wayland-sessions";
      user = "greeter";
    };
    initial_session = {
      command = "${richenLib.wrappers.mango-laptop}/bin/mango";
      user = "richen";
    };
  };

}
