{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.modules.gamescope-nvidia;

  # Helper script for gamescope with NVIDIA
  gameScope = pkgs.writeScriptBin "gamescope-nvidia" ''
    #!${pkgs.bash}/bin/bash

    # Check if GPU is bound to vfio
    if lspci -k | grep -A 2 NVIDIA | grep "Kernel driver in use: vfio-pci"; then
      echo "Unbinding NVIDIA GPU from vfio..."
      vfio unbind
      sleep 2
    fi

    # Launch gamescope with AMD GPU
    gamescope \
      --hdr-enabled \
      --adaptive-sync \
      --expose-wayland \
      --rt \
      --prefer-output ${cfg.preferredOutput} \
      -W ${toString cfg.width} \
      -H ${toString cfg.height} \
      -r ${toString cfg.refreshRate} \
      -- "$@"

    # Optionally rebind to vfio after closing
    if [ ${toString cfg.autoRebindVfio} = true ]; then
      echo "Rebinding NVIDIA GPU to vfio..."
      vfio bind
    fi
  '';

in
{
  options.modules.gamescope-nvidia = {
    enable = mkEnableOption "Enable gamescope with NVIDIA passthrough support";

    width = mkOption {
      type = types.int;
      default = 2560;
      description = "Default gamescope width";
    };

    height = mkOption {
      type = types.int;
      default = 1440;
      description = "Default gamescope height";
    };

    refreshRate = mkOption {
      type = types.int;
      default = 60;
      description = "Default refresh rate";
    };

    preferredOutput = mkOption {
      type = types.str;
      default = "DP-5";
      description = "Preferred display output";
    };

    autoRebindVfio = mkOption {
      type = types.bool;
      default = true;
      description = "Automatically rebind GPU to vfio after closing gamescope";
    };
  };

  config = mkIf cfg.enable {
    # Required packages
    environment.systemPackages = with pkgs; [
      gamescope
      gameScope
      vulkan-tools
      vulkan-loader
      vulkan-validation-layers
      libva
      vaapiVdpau
      mesa # Add mesa for AMD support
      mesa.drivers # Add mesa drivers
    ];

    # Enable required hardware acceleration
    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [
          vaapiVdpau
          libvdpau-va-gl
        ];
      };
      nvidia = {
        package = config.boot.kernelPackages.nvidiaPackages.stable;
        modesetting.enable = true;
        powerManagement.enable = true;
        prime = {
          offload.enable = true;
          # AMD GPU as primary
          amdgpuBusId = "PCI:3:0:0"; # Adjust this to match your setup
          nvidiaBusId = "PCI:8:0:0"; # Adjust this to match your setup
        };
      };
    };
  };
}
