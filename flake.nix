{
  description = "template for hydenix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    hydenix = {
      url = "github:richen604/hydenix";
      # url = "path:/media/backup_drive/Dev/hydenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixpkgs-mesa-25-1-7 = {
      url = "github:nixos/nixpkgs/ca3d8cc5c4f3132f5515787507bcf91fd46cd2de";
      flake = false;
    };

    richendots-private = {
      #url = "git+ssh://git@github.com/richen604/richendots-private.git?ref=main";
      url = "path:/media/backup_drive/Dev/richendots-private";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nix-index-database - for comma and command-not-found
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      ...
    }@inputs:
    let
      # Create a function to generate host configurations
      mkHost =
        hostname:
        inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
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

      # All below is for deploy-rs

      system = "x86_64-linux";

      # Unmodified nixpkgs
      pkgs = import inputs.nixpkgs { inherit system; };

      # nixpkgs with deploy-rs overlay but force the nixpkgs package for binary cache
      deployPkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [
          inputs.deploy-rs.overlays.default
          (self: super: {
            deploy-rs = {
              inherit (pkgs) deploy-rs;
              lib = super.deploy-rs.lib;
            };
          })
        ];
      };

      mkDeployNode = hostname: {
        hostname = "${hostname}.build";
        profiles.system = {
          path = deployPkgs.deploy-rs.lib.activate.nixos self.nixosConfigurations.${hostname};
          user = "root";
        };
      };

    in
    {
      nixosConfigurations = {
        fern = mkHost "fern";
        oak = mkHost "oak";
        cedar = mkHost "cedar";
      };

      deploy = {
        nodes = {
          fern = mkDeployNode "fern";
          oak = mkDeployNode "oak";
          cedar = mkDeployNode "cedar";
        };
      };

      packages.${system} = {
        fern-vm = mkVm "fern";
        oak-vm = mkVm "oak";
        cedar-vm = mkVm "cedar";

        fern = (mkHost "fern").config.system.build.toplevel;
        oak = (mkHost "oak").config.system.build.toplevel;
        cedar = (mkHost "cedar").config.system.build.toplevel;

        rb = pkgs.writeShellScriptBin "rb" ''
          host=$1
          case "$host" in
            "oak")
              ${deployPkgs.deploy-rs.deploy-rs}/bin/deploy .#oak ;;
            "fern")
              ${deployPkgs.deploy-rs.deploy-rs}/bin/deploy .#fern ;;
            "cedar")
              ${deployPkgs.deploy-rs.deploy-rs}/bin/deploy .#cedar ;;
            "all")
              ${deployPkgs.deploy-rs.deploy-rs}/bin/deploy .#oak
              ${deployPkgs.deploy-rs.deploy-rs}/bin/deploy .#fern
              ${deployPkgs.deploy-rs.deploy-rs}/bin/deploy .#cedar
              ;;
            *) echo "Usage: rb [oak|fern|cedar|all]" ;;
          esac
        '';
      };

      # Deploy-rs checks
      checks.${system} = inputs.deploy-rs.lib.${system}.deployChecks self.deploy;

    };
}
