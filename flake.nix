{
  description = "template for hydenix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    hydenix = {
      url = "github:richen604/hydenix";
      # url = "path:/media/backup_drive/Dev/hydenix";
      # inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    richendots-private = {
      # url = "git+ssh://git@github.com/richen604/richendots-private.git?ref=main";
      url = "path:/home/richen/newdev/richendots-private";
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

    wrappers.url = "github:lassulus/wrappers";

    vicinae.url = "github:vicinaehq/vicinae";
  };

  outputs =
    {
      self,
      ...
    }@inputs:
    let

      # TODO: if this is expanded it should be a separate file
      richenLib = {
        wrappers = pkgs.callPackage ./wrappers {inherit inputs pkgs richenLib;};
      };

      # Create a function to generate host configurations
      mkHost =
        hostname:
        inputs.nixpkgs.lib.nixosSystem {
          # system = "x86_64-linux";
          specialArgs = {
            inputs = inputs // inputs.richendots-private.inputs;
            hostname = hostname;
            inherit richenLib;
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
          sshOpts =
            if hostname == "cedar" then
              [
                "-p"
                "2222"
              ]
            else
              [ ];
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
        vm = {
          fern = mkVm "fern";
          oak = mkVm "oak";
          cedar = mkVm "cedar";
          mango = mkVm "mangowc";
        };
        # Wrapped programs namespace
        wrapped = richenLib.wrappers;
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
