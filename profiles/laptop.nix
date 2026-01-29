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

}
