{
  pkgs,
  config,
  lib,
  ...
}:

let
  cfg = config.modules.boot;
in
{

  options.modules.boot = {
    enable = lib.mkEnableOption "boot";
  };

  config = lib.mkIf cfg.enable {
    hydenix.boot.enable = false;

    boot = {
      plymouth.enable = true;
      kernelPackages = pkgs.linuxPackages_zen;
      loader.systemd-boot.enable = pkgs.lib.mkForce false;
      loader = {
        efi = {
          canTouchEfiVariables = true;
        };
        grub = {
          enable = true;
          device = "nodev";
          useOSProber = true;
          efiSupport = true;
          theme = pkgs.hydenix.grub-retroboot;
          extraEntries = ''
            menuentry "UEFI Firmware Settings" {
              fwsetup
            }
          '';
        };
      };
      kernelModules = [
        "v4l2loopback"
      ];
      extraModprobeConfig = ''
        options v4l2loopback devices=2 video_nr=1,2 card_label="OBS Cam, Virt Cam" exclusive_caps=1
      '';
      resumeDevice = "/dev/disk/by-uuid/92615496-7f61-4930-8fe0-48ac125f02e8";
    };

    environment.systemPackages = with pkgs; [
      efibootmgr
      os-prober
    ];
  };
}
