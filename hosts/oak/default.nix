{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
  ];

  # intel specific
  hardware.cpu.intel.updateMicrocode = true;

  boot.initrd.kernelModules = [
    "i915"
  ];

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
      nvidiaSettings = false;
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

  environment.systemPackages = [
    pkgs.moonlight-qt
  ];

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "/home/richen/mutagen/richendots";
  };

  nix.settings = {
    connect-timeout = 2;
    substituters = lib.mkForce [
      "http://cedar.richen.sh:5000?priority=10"
      "https://doom-emacs-unstraightened.cachix.org?priority=20"
      "https://cache.nixos-cuda.org?priority=30"
      "https://cache.nixos.org?priority=40"
    ];
  };

  services.nixpull = {
    enable = true;
    role = "client";
    server.user = "richen";
    notify = {
      enable = true;
      users = [ "richen" ];
    };
  };

  system.stateVersion = "26.05";
}
