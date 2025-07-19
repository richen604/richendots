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
    ./hardware-configuration.nix
    ../../modules/system/hosts/oak
    ../common/private.nix
  ];

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
