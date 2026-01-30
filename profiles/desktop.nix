{ richenLib, pkgs, ... }:
{

  #packages
  environment.systemPackages = [
    richenLib.wrappers.mango
  ];

  environment.etc."mango/config.conf".source =
    pkgs.writeText "config.conf" richenLib.wrappers.mango.passthru.config;

  # greetd configuration
  services.greetd.settings = {
    default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --sessions ${richenLib.wrappers.mango}/share/wayland-sessions";
      user = "greeter";
    };
    initial_session = {
      command = "${pkgs.dbus}/bin/dbus-run-session ${richenLib.wrappers.mango}/bin/mango";
      user = "richen";
    };
  };

}
