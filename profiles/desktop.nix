{ richenLib, pkgs, ... }:
{

  #packages
  environment.systemPackages = [
    richenLib.wrappers.mango
  ];

  environment.etc."mango/config.conf".source =
    pkgs.writeText "config.conf" richenLib.wrappers.mango.passthru.config;

  # greetd configuration
  services.greetd.settings = rec {
    initial_session = {
      command = "${richenLib.wrappers.mango}/bin/mango";
      user = "richen";
    };
    default_session = initial_session;
  };

}
