{
  inputs,
  ...
}:
let
  pkgs = import inputs.hydenix.inputs.hydenix-nixpkgs {
    inherit (inputs.hydenix.lib) system;
    config.allowUnfree = true;
    config.allowBroken = true;
    overlays = [
      inputs.hydenix.lib.overlays
      (final: prev: {
        userPkgs = import inputs.nixpkgs {
          inherit (inputs.hydenix.lib) system;
          config.allowUnfree = true;
          config.allowBroken = true;
        };
      })
    ];
  };
in
{

  nixpkgs.pkgs = pkgs;

  imports = [
    inputs.hydenix.inputs.home-manager.nixosModules.home-manager
    inputs.hydenix.lib.nixOsModules

    inputs.nixos-hardware.nixosModules.common-pc-laptop
    inputs.nixos-hardware.nixosModules.common-hidpi
    inputs.nixos-hardware.nixosModules.common-pc-ssd

    inputs.nixos-hardware.nixosModules.common-gpu-intel
    inputs.nixos-hardware.nixosModules.common-gpu-nvidia
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    ./hardware-configuration.nix
    ../../modules/system/hosts/oak
    ../common/private.nix
  ];

  # NVIDIA PRIME for hybrid graphics (Intel + NVIDIA)
  hardware.nvidia.prime = {
    # Enable NVIDIA Optimus support
    offload = {
      enable = true;
      enableOffloadCmd = true; # Provides nvidia-offload command
    };
    # Bus IDs found via: lspci | grep -E "(VGA|3D)"
    # 0000:00:02.0 VGA compatible controller: Intel Corporation Raptor Lake-P [Iris Xe Graphics] (rev 04)
    # 0000:01:00.0 VGA compatible controller: NVIDIA Corporation AD107M [GeForce RTX 4060 Max-Q / Mobile] (rev a1)
    intelBusId = "PCI:0:2:0"; # Intel Raptor Lake-P Iris Xe Graphics
    nvidiaBusId = "PCI:1:0:0"; # NVIDIA GeForce RTX 4060 Max-Q / Mobile
  };
  hardware.nvidia.open = true;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs;
    };
    users."richen" =
      { ... }:
      {
        imports = [
          ../../modules/hm/users/richen
        ];

        desktops.hydenix = {
          enable = true;
          hostname = "oak";
        };

        modules = {
          common = {
            easyeffects.enable = true;
            git.enable = true;
            dev.enable = true;
            expo-dev.enable = true;
            obs.enable = true;
            games.enable = true;
            zsh.enable = true;
          };
          # TODO: make obsidian.nix work on any host
          obsidian.enable = false;
        };
      };
  };

  hydenix = {
    enable = true;
    hostname = "oak";
    timezone = "America/Vancouver";
    locale = "en_CA.UTF-8";
  };

  # GRUB configuration for high-DPI display
  # TODO: move this to a module
  boot.loader.grub = {
    fontSize = 32; # Larger font for high-DPI screen
    gfxmodeEfi = "1920x1200"; # Lower resolution for better readability
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    # todo: flake path for oak
  };
  # for nh.clean
  nix.gc.automatic = pkgs.lib.mkForce false;

  users.users.richen = {
    isNormalUser = true;
    initialPassword = "hydenix";
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
    ];
    shell = pkgs.zsh;
  };
}
