{
  config,
  pkgs,
  ...
}:
{
  hardware.cpu.intel.updateMicrocode = true;

  boot.blacklistedKernelModules = [
    "xe"
  ];
  boot.initrd.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];
  boot.kernelParams = [
    "nvidia_modeset.conceal_vrr_caps=1"
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

  services.udev.extraRules = ''
    SUBSYSTEM=="drm", KERNEL=="card*", KERNELS=="0000:01:00.0", SYMLINK+="dri/nvidia-card"
    SUBSYSTEM=="drm", KERNEL=="card*", KERNELS=="0000:00:02.0", SYMLINK+="dri/intel-card"
  '';
}
