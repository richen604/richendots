{
  pkgs,
  config,
  lib,
  inputs,
  ...
}:

let
  cfg = config.modules.drivers;
in
{
  # imports = lib.mkIf cfg.enable [
  #   inputs.nixos-hardware.nixosModules.common-gpu-amd
  #   inputs.nixos-hardware.nixosModules.common-cpu-intel
  # ];

  options.modules.drivers = {
    enable = lib.mkEnableOption "drivers";
  };

  config = lib.mkIf cfg.enable {

    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
      };
      nvidia = pkgs.lib.mkForce {
        modesetting.enable = true;
        powerManagement.enable = false;
        open = false;
        nvidiaSettings = true;
        package = config.boot.kernelPackages.nvidiaPackages.stable;
        prime = {
          offload = {
            enable = true;
            enableOffloadCmd = true;
          };
          amdgpuBusId = "PCI:3:0:0";
          nvidiaBusId = "PCI:8:0:0";
        };
      };

      amdgpu = {
        initrd.enable = true;
      };
    };

    services.xserver = {
      enable = true;
      videoDrivers = [
        "amdgpu"
        "nvidia"
      ];
    };
  };
}
