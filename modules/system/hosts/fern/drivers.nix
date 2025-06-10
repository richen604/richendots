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
        extraPackages = [
          pkgs.nvidia-vaapi-driver
          pkgs.intel-media-driver
          pkgs.amdvlk
          pkgs.vulkan-loader
          pkgs.vulkan-validation-layers
          pkgs.mesa.drivers
        ];
        extraPackages32 = [
          pkgs.pkgsi686Linux.amdvlk
          pkgs.pkgsi686Linux.mesa.drivers
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

      nvidia = pkgs.lib.mkForce {
        modesetting.enable = true;
        powerManagement.enable = false;
        open = true;
        nvidiaSettings = true;
        package = config.boot.kernelPackages.nvidiaPackages.stable;
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

    # Configure Gamescope with proper PRIME offload support
    programs.gamescope = {
      enable = true;
      args = [
        # "--expose-wayland"
        "-f"
        # "-e"
        "-W 2560"
        "-H 1440"
        "--nested-refresh 60"
        "--filter linear"
        "--backend sdl"
      ];
      env = {
        # For Prime render offload on Nvidia laptops (from NixOS docs)
        __NV_PRIME_RENDER_OFFLOAD = "1";
        __VK_LAYER_NV_optimus = "NVIDIA_only";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        # Keep AMD for Gamescope compositor
        DRI_PRIME = "0";
      };
    };

    environment.variables = {
      # Global Vulkan ICD setup - both AMD and NVIDIA available
      VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json:/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.json";
    };
  };
}
