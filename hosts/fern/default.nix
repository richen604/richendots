{
  inputs,
  config,
  ...
}:
let
  pkgs = import inputs.nixpkgs {
    system = "x86_64-linux";
    config.allowUnfree = true;
    config.allowBroken = true;
    overlays = [
      inputs.hydenix.overlays.default
      # This new overlay will downgrade mesa
      (final: prev: {
        mesa =
          (import inputs.nixpkgs-mesa-25-1-7 {
            system = prev.system;
            config.allowUnfree = true;
          }).mesa;
      })
    ];
  };
in
{

  nixpkgs.pkgs = pkgs;

  imports = [
    inputs.hydenix.inputs.home-manager.nixosModules.home-manager
    inputs.hydenix.nixosModules.default
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
      { config, ... }:
      {
        imports = [
          inputs.hydenix.homeModules.default
          ../../modules/hm/users/richen
        ];

        desktops.hydenix = {
          enable = true;
          hostname = "fern";
        };

        home.stateVersion = "25.05";
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

  # for spotify
  services.flatpak.enable = true;
  environment.systemPackages = with pkgs; [
    spicetify-cli
  ];

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
