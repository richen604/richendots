{
  description = "template for hydenix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    hydenix = {
      # url = "github:richen604/hydenix/dev";
      url = "path:/home/richen/hydenix";
    };
    chaotic.url = "github:chaotic-cx/nyx/18c577a2a160453f4a6b4050fb0eac7d28b92ead";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs =
    {
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      # User's pkgs instance
      pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      hydenixConfig = inputs.hydenix.lib.mkConfig {
        userConfig = import ./config.nix;
        extraInputs = inputs;
        # Pass user's pkgs to be used alongside hydenix's pkgs (eg. userPkgs.kitty)
        extraPkgs = pkgs;
      };
    in
    {

      nixosConfigurations.${hydenixConfig.userConfig.host} = hydenixConfig.nixosConfiguration;

      packages.${system} = {
        # Packages below load your config in ./config.nix

        # defaults to nix-vm - nix run .
        default = hydenixConfig.nix-vm.config.system.build.vm;

        # NixOS build packages - sudo nixos-rebuild switch/test --flake .#hydenix
        hydenix = hydenixConfig.nixosConfiguration;

        # Home activation packages - nix run .#hm / nix run .#hm-generic / home-manager switch/test --flake .#hm or .#hm-generic
        hm = hydenixConfig.homeConfigurations.${hydenixConfig.userConfig.username}.activationPackage;
        hm-generic =
          hydenixConfig.homeConfigurations."${hydenixConfig.userConfig.username}-generic".activationPackage;

        # EXPERIMENTAL VM BUILDERS - nix run .#arch-vm / nix run .#fedora-vm
        arch-vm = hydenixConfig.arch-vm.default;
        fedora-vm = hydenixConfig.fedora-vm.default;
      };
    };
}
