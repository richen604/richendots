{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/common.nix
    ../../profiles/common-gui.nix
    ../../profiles/laptop.nix
  ];

  networking.hostName = "oak";

  # laptop specific
  services.tlp.enable = true;

  # intel specific
  hardware.cpu.intel.updateMicrocode = true;

  boot.initrd.kernelModules = [
    "i915"
  ];

  powerManagement.enable = true;
  services.thermald.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_zen;

  hardware = {
    graphics = {
      enable = true;
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

    nvidia = {
      open = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      prime = {
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
        intelBusId = "PCI:0:2:0"; # Intel Raptor Lake-P Iris Xe Graphics
        nvidiaBusId = "PCI:1:0:0"; # NVIDIA GeForce RTX 4060 Max-Q / Mobile
      };
    };
  };

  services.xserver = {
    videoDrivers = [
      "modesetting"
      "nvidia"
    ];
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "/home/richen/mutagen/richendots";
  };
  # for nh.clean
  nix.gc.automatic = lib.mkForce false;

  system.stateVersion = "26.05";
}
