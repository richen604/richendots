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
      url = "git+ssh://git@github.com/richen604/richendots-private.git";
    };
  };

  outputs =
    {
      ...
    }@inputs:
    let
      HOSTNAME = "fern";

      hydenixConfig = inputs.hydenix.inputs.hydenix-nixpkgs.lib.nixosSystem {
        inherit (inputs.hydenix.lib) system;
        specialArgs = {
          inputs = inputs // inputs.richendots-private.inputs;
        };
        modules = [
          ./configuration.nix
        ];
      };

      # Create VM variant of the NixOS configuration
      fern-vm = import ./hosts/vm/fern-vm.nix {
        inherit inputs;
        nixosConfiguration = hydenixConfig;
      };

      isoConfig = inputs.hydenix.lib.iso {
        hydenix-inputs = inputs.hydenix.inputs // inputs.hydenix.lib // inputs.hydenix;
      };
    in
    {

      nixosConfigurations.${HOSTNAME} = hydenixConfig;
      nixosConfigurations.nixos = hydenixConfig;

      packages.${inputs.hydenix.lib.system} = {
        default = hydenixConfig;
        fern-vm = fern-vm.config.system.build.vm;
        build-iso = isoConfig.build-iso;
        burn-iso = isoConfig.burn-iso;
      };
    };
}
