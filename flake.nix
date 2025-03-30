{
  description = "template for hydenix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    hydenix = {
      url = "github:richen604/hydenix";
    };
    chaotic.url = "github:chaotic-cx/nyx/18c577a2a160453f4a6b4050fb0eac7d28b92ead";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    richendots-private = {
      url = "git+ssh://git@github.com/richen604/richendots-private.git?ref=main";
    };
  };

  outputs =
    {
      ...
    }@inputs:
    let
      # Create a function to generate host configurations
      mkHost =
        hostname:
        inputs.hydenix.inputs.hydenix-nixpkgs.lib.nixosSystem {
          inherit (inputs.hydenix.lib) system;
          specialArgs = {
            inputs = inputs // inputs.richendots-private.inputs;
            hostname = hostname;
          };
          modules = [
            ./hosts/${hostname}
          ];
        };

      # Create VM variant function
      mkVm =
        hostname:
        (import ./hosts/vm.nix {
          inherit inputs hostname;
          nixosConfiguration = mkHost hostname;
        }).config.system.build.vm;

      isoConfig = inputs.hydenix.lib.iso {
        hydenix-inputs = inputs.hydenix.inputs // inputs.hydenix.lib // inputs.hydenix;
        flake = inputs.self.outPath;
      };
    in
    {
      nixosConfigurations = {
        fern = mkHost "fern";
        oak = mkHost "oak";
        # TODO: temp host for rebuild iso
        nixos = mkHost "oak";
      };

      packages.${inputs.hydenix.lib.system} = {
        fern-vm = mkVm "fern";
        oak-vm = mkVm "oak";
        build-iso = isoConfig.build-iso;
        burn-iso = isoConfig.burn-iso;
      };
    };
}
