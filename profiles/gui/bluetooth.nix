{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.bluez
    pkgs.bluez-tools
    pkgs.blueman
  ];

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings.General.Experimental = true;
  };
  services.blueman.enable = true;
}
