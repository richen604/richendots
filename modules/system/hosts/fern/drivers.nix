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
        package = pkgs.mesa;
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
          # TODO: Downgraded to 25.1.5 due to a memory leak with looking-glass.
          # This is handled via an overlay in hosts/fern/default.nix for the 'fern' host.
          # Remove the overlay once the memory leak is fixed upstream.
          mesa
          libva
          libva-vdpau-driver
        ];
        package32 = pkgs.pkgsi686Linux.mesa;
        extraPackages32 = with pkgs.pkgsi686Linux; [
          # amdvlk  # Remove this line too
          mesa
          vulkan-loader
          libva
          libva-vdpau-driver
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
        # package = lib.mkForce config.boot.kernelPackages.nvidiaPackages.stable;
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

    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = "radeonsi";
      LIBVA_DRIVERS_PATH = "/run/opengl-driver/lib/dri";
      LIBVA_DEVICE = "/dev/dri/renderD128";
      VDPAU_DRIVER = "radeonsi";
      __GLX_VENDOR_LIBRARY_NAME = "mesa";
      AMD_VULKAN_ICD = "RADV";
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

      (pkgs.writeShellScriptBin "prime-run" ''
        export __NV_PRIME_RENDER_OFFLOAD=1
        export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
        export __GLX_VENDOR_LIBRARY_NAME=nvidia
        export __VK_LAYER_NV_optimus=NVIDIA_only
        export __NV_PRIME_VK=1
        export VK_ICD_FILENAMES=/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.json
        exec "$@"
      '')
    ];

    # Ensure proper driver loading
    boot.kernelModules = [ "amdgpu" ];
  };
}
