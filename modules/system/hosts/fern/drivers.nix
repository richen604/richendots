{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  cfg = config.modules.fern.drivers;
in
{

  imports = [
    inputs.nixos-hardware.nixosModules.common-gpu-amd
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-gpu-intel
  ];

  options.modules.fern.drivers = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable drivers";
    };
  };

  config = lib.mkIf cfg.enable {

    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [
          (config.boot.kernelPackages.nvidiaPackages.beta)
          # NVIDIA drivers
          nvidia-vaapi-driver
          # Intel drivers
          intel-media-driver
          intel-vaapi-driver
          # AMD drivers - using RADV instead of AMDVLK
          # Vulkan essentials
          vulkan-loader
          vulkan-validation-layers
          vulkan-tools
          # Mesa (includes RADV - the better AMD Vulkan driver)
          mesa.drivers
        ];
        extraPackages32 = with pkgs.pkgsi686Linux; [
          # amdvlk  # Remove this line too
          mesa.drivers
          vulkan-loader
          (config.boot.kernelPackages.nvidiaPackages.beta)
        ];
      };

      # Add Bluetooth configuration
      bluetooth = {
        enable = true;
        powerOnBoot = true;
        settings = {
          General = {
            Enable = "Source,Sink,Media,Socket";
            Experimental = true;
          };
        };
      };

      nvidia = {
        modesetting.enable = true;
        powerManagement.enable = false;
        open = true;
        nvidiaSettings = true;
        package = config.boot.kernelPackages.nvidiaPackages.beta;
        prime = {
          offload = {
            enable = true;
            enableOffloadCmd = true;
          };
          sync.enable = false;
          amdgpuBusId = "PCI:3:0:0";
          nvidiaBusId = "PCI:8:0:0";
        };
      };
    };

    services.xserver = {
      videoDrivers = [
        "amdgpu"
        "nvidia"
      ];
    };

    # Add system packages for Vulkan debugging and Steam compatibility
    environment.systemPackages = with pkgs; [
      vulkan-tools
      vulkan-loader
      vulkan-validation-layers
      mesa-demos
      glxinfo
      # Additional debugging tools
      radeontop
      nvidia-system-monitor-qt
      # Wayland-specific tools
      wayland-utils
      psmisc
    ];

    # Ensure proper driver loading
    boot.kernelModules = [ "amdgpu" ];
  };
}
