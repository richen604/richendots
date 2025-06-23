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
          mesa
        ];
        extraPackages32 = with pkgs.pkgsi686Linux; [
          # amdvlk  # Remove this line too
          mesa
          vulkan-loader
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
        open = false;
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

    # Configure Gamescope with proper PRIME offload support
    programs.gamescope = {
      enable = true;
      args = [
        "-f"
        "-W 2560"
        "-H 1440"
        "--nested-refresh 60"
        "--filter linear"
        "--backend sdl"
      ];
      env = {
        # For Prime render offload on Nvidia laptops
        __NV_PRIME_RENDER_OFFLOAD = "1";
        __VK_LAYER_NV_optimus = "NVIDIA_only";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        # Keep AMD for Gamescope compositor
        DRI_PRIME = "0";
      };
    };

    environment.variables = {
      # Simplified Vulkan configuration - let the system auto-detect
      VULKAN_LOG_LEVEL = "info";
      # Filter out problematic drivers
      VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json:/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.x86_64.json";
      # Force Wayland for Vulkan applications
      SDL_VIDEODRIVER = "wayland";
      # Additional Wayland environment variables
      WAYLAND_DISPLAY = "wayland-1";
      XDG_SESSION_TYPE = "wayland";
      # NVIDIA specific variables for better compatibility
      __GL_SYNC_TO_VBLANK = "0";
      __GL_VRR_ALLOWED = "1";
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
    ];

    # Ensure proper driver loading
    boot.kernelModules = [ "amdgpu" ];

    # Add udev rules for proper GPU access
    services.udev.extraRules = ''
      # AMD GPU
      KERNEL=="renderD*", GROUP="video", MODE="0666"
      # NVIDIA GPU  
      KERNEL=="nvidia*", GROUP="video", MODE="0666"
    '';
  };
}
