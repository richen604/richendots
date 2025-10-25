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
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable boot configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    hydenix.boot.enable = false;

    boot = {
      plymouth.enable = true;
      kernelPackages = lib.mkForce pkgs.linuxPackages_6_12;
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
    };

    environment.systemPackages = with pkgs; [
      efibootmgr
      os-prober
    ];
  };
}
