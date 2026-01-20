{
  config,
  pkgs,
  lib,
  ...
}:
{

  # intel specific
  hardware.cpu.intel.updateMicrocode = true;

  # amd specific
  hardware.amdgpu.initrd.enable = lib.mkDefault true;

  # we are skipping nvidia from initrd, adding vfio
  boot.initrd.kernelModules = lib.mkForce [
    "amdgpu"
    "i915"
    "vfio_pci"
    "vfio"
    "vfio_iommu_type1"
  ];

  hardware = {
    graphics = {
      enable = true;
      package = pkgs.mesa;
      enable32Bit = true;
      extraPackages = with pkgs; [

        nvidia-vaapi-driver
        vulkan-loader
        vulkan-validation-layers
        vulkan-tools
        libva
        libva-vdpau-driver

        # intel
        intel-media-driver
        intel-compute-runtime
        vpl-gpu-rt
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
      "modesetting"
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
  environment.systemPackages = [
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
}
