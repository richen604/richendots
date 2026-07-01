{
  config,
  ...
}:
{

  hardware.cpu.intel.updateMicrocode = true;

  boot.blacklistedKernelModules = [
    "i915"
    "xe"
  ];

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };

    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      open = true;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };
  services.xserver = {
    videoDrivers = [
      "nvidia"
    ];
  };
}
