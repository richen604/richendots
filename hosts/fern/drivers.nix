{
  config,
  pkgs,
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
      extraPackages = with pkgs; [
        libva
        libva-vdpau-driver
        nvidia-vaapi-driver
        vulkan-loader
        vulkan-tools
      ];
    };

    nvidia = {
      modesetting.enable = true;
      nvidiaSettings = false;
      powerManagement.enable = true;
      open = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };
  services.xserver = {
    videoDrivers = [
      "nvidia"
    ];
  };
}
