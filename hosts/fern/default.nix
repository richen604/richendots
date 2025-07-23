{
  inputs,
  config,
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
    ../../modules/system/hosts/fern
    ../common/private.nix
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs;
      osConfig = config;
    };
    users."richen" =
      { ... }:
      {
        imports = [
          ../../modules/hm/users/richen
        ];

        desktops.hydenix = {
          enable = true;
          hostname = "fern";
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
          obsidian.enable = true;
        };
      };
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "/home/richen/dev/richendots";
  };
  # for nh.clean
  nix.gc.automatic = pkgs.lib.mkForce false;

  hydenix = {
    enable = true;
    hostname = "fern";
    timezone = "America/Vancouver";
    locale = "en_CA.UTF-8";
  };

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

  system.stateVersion = "25.05";
}
