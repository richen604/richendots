{ pkgs, ... }:
{
  boot = {
    kernelPackages = pkgs.linuxPackages_zen;
    kernel.sysctl."fs.protected_hardlinks" = 1;
    tmp.cleanOnBoot = true;
    loader.efi.canTouchEfiVariables = true;
    loader.grub = {
      enable = true;
      configurationLimit = 3;
      device = "nodev";
      efiSupport = true;
      efiInstallAsRemovable = false;
      useOSProber = true;
      extraEntries = ''
        menuentry "UEFI Firmware Settings" {
          fwsetup
        }
      '';
    };
  };

  services.fwupd.enable = true;
}
