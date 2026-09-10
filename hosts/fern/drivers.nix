{
  config,
  pkgs,
  ...
}:
let
  nvidiaPackage = config.boot.kernelPackages.nvidiaPackages.mkDriver {
    version = "615.71.09";
    sha256_64bit = "sha256-zc7tIrvrYSSNGm3qvCWWZz46ZQFpjucayNL9wo87cP4=";
    sha256_aarch64 = "sha256-IbekQhE7cFfmnPZaLY9NDYcF7CoNZ+2Qb7sRd4EOgWM=";
    openSha256 = "sha256-3gByMYIwFzRaLdDG+roCEOuKRRJDrljG9AlLnRZTirM=";
    settingsSha256 = "sha256-LK1LU8mDkM/XVRKPBtuOZh9nIP/lGFLAJnmasEX8jhg=";
    persistencedSha256 = "sha256-qPRb+3d88+2RcpUkoBTbjIaImnQ+jX+/6p1vXcJ5geE=";
  };
in
{
  assertions = [
    {
      assertion = config.hardware.nvidia.package.version == "615.71.09";
      message = "fern requires NVIDIA 615.71.09";
    }
  ];

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
      package = nvidiaPackage;
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
