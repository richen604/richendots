{
  config,
  pkgs,
  ...
}:
{

  # intel specific
  hardware.cpu.intel.updateMicrocode = true;

  boot.initrd.kernelModules = [
    "i915"
  ];

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };

    nvidia = {
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

  environment.systemPackages = [
    (pkgs.writeScriptBin "prime-run" ''
      #!/usr/bin/env bash
      export __NV_PRIME_RENDER_OFFLOAD=1
      export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export __VK_LAYER_NV_optimus=NVIDIA_only
      export VK_ICD_FILENAMES=/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.x86_64.json
      export VK_LAYER_PATH=/run/opengl-driver/share/vulkan/explicit_layer.d
      exec "$@"
    '')
  ];
}
