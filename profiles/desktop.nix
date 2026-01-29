{ richenLib, pkgs, ... }:
{

  #packages
  environment.systemPackages = [
    richenLib.wrappers.mango
  ];

  environment.etc."mango/config.conf".source =
    pkgs.writeText "config.conf" richenLib.wrappers.mango.passthru.config;

}
