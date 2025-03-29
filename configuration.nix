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
    ./modules/system
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
          inputs.hydenix.lib.homeModules
          ./modules/hm
        ];
      };
  };

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

  # TODO: temporary packages
  environment.systemPackages = with pkgs; [
    keepassxc
    # Yubikey packages
    yubikey-manager # CLI tool for managing Yubikeys
    yubikey-manager-qt # GUI tool for managing Yubikeys
    pam_u2f # U2F PAM module
    yubikey-personalization # Yubikey personalization tool
    yubikey-personalization-gui # GUI for Yubikey personalization
    age-plugin-yubikey # Age plugin for Yubikey
  ];
}
