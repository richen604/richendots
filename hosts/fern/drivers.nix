{
  config,
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
    ];
  };
}
