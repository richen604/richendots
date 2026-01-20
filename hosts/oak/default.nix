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

  boot = {
    plymouth.enable = true;
    kernelPackages = lib.mkForce pkgs.linuxPackages_6_12;
    loader.systemd-boot.enable = pkgs.lib.mkForce false;
    loader = {
      efi = {
        canTouchEfiVariables = true;
      };
      grub = {
        enable = true;
        device = "nodev";
        useOSProber = true;
        efiSupport = true;
        extraEntries = ''
          menuentry "UEFI Firmware Settings" {
            fwsetup
          }
        '';
      };
    };
  };

  # laptop specific
  services.tlp.enable = true;

  # intel specific
  hardware.cpu.intel.updateMicrocode = true;

  # we are skipping nvidia from initrd, adding vfio
  boot.initrd.kernelModules = lib.mkForce [
    "i915"
  ];

  powerManagement.enable = true;
  services.thermald.enable = true;
  services.auto-cpufreq = {
    enable = true;
    settings = {
      battery = {
        governor = "powersave";
        turbo = "never";
      };
      charger = {
        governor = "performance";
        turbo = "auto";
      };
    };
  };

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

  # for high-DPI display
  # TODO: move this to a module
  boot.loader.grub = {
    fontSize = 32;
    gfxmodeEfi = "1920x1200";
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    # todo: flake path for oak
  };
  # for nh.clean
  nix.gc.automatic = lib.mkForce false;

  users.users.richen = {
    isNormalUser = true;
    initialPassword = "hydenix";
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
    ];
  };

  system.stateVersion = "26.05";
}
