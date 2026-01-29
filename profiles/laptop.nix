{ richenLib, pkgs, ... }:
{

  #packages
  environment.systemPackages = [
    richenLib.wrappers.mango-laptop
  ];

  hjem.users.richen.files.".config/mango/config.conf" = {
    type = "copy";
    permissions = "0644";
    source = pkgs.writeText "config.conf" richenLib.wrappers.mango-laptop.passthru.config;
  };

  boot.loader.grub = {
    gfxmodeEfi = "1024x768";
  };

}
