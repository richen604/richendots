{ richenLib, pkgs, ... }:
{

  #packages
  environment.systemPackages = [
    richenLib.wrappers.mango-laptop
  ];

  environment.etc."mango/config.conf".source =
    pkgs.writeText "config.conf" richenLib.wrappers.mango-laptop.passthru.config;

}
