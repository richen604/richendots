{
  description = "template for hydenix";

  inputs = {
    nixpkgs.follows = "hydenix/nixpkgs";
    hydenix = {
      url = "github:richen604/hydenix";
      # url = "path:/home/richen/newdev/hydenix";
    };
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    richendots-private = {
      url = "git+ssh://git@github.com/richen604/richendots-private.git?ref=main";
      # url = "path:/home/richen/newdev/richendots-private";
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
    hjem-rum = {
      url = "github:snugnug/hjem-rum";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.hjem.follows = "hjem";
    };
    hjem = {
      url = "github:feel-co/hjem";
      inputs.nixpkgs.follows = "hjem-rum/hjem";
    };
  };

  outputs =
    {
      ...
    }@inputs:
    let

      forEachSystem =
        f:
        inputs.nixpkgs.lib.genAttrs [
          "x86_64-linux"
          "aarch64-linux"
        ] (system: f system);

      # flatten nested attribute sets with dash separators
      flattenAttrs =
        let
          go =
            prefix: set:
            inputs.nixpkgs.lib.concatMapAttrs (
              name: value:
              let
                key = if prefix == "" then name else "${prefix}-${name}";
              in
              if inputs.nixpkgs.lib.isDerivation value then
                { ${key} = value; }
              else if inputs.nixpkgs.lib.isAttrs value then
                go key value
              else
                { }
            ) set;
        in
        go "";

      # Create a function to generate host configurations
      mkHost =
        hostname: system:
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          richenLib = {
            wrappers = pkgs.callPackage ./wrappers { inherit inputs; };
          };
        in
        inputs.nixpkgs.lib.nixosSystem {
          inherit pkgs system;
          specialArgs = {
            inputs = inputs // inputs.richendots-private.inputs;
            inherit hostname richenLib;
          };
          modules = [
            ./hosts/${hostname}
          ];
        };

      # Create VM variant function
      mkVm =
        hostname: system:
        (import ./hosts/vm.nix {
          inherit inputs hostname;
          nixosConfiguration = mkHost hostname system;
        }).config.system.build.vm;

      # nixpkgs with deploy-rs overlay but force the nixpkgs package for binary cache
      # todo: unify with above pkgs definition
      deployPkgs = import inputs.nixpkgs {
        system = "x86_64-linux";
        overlays = [
          inputs.deploy-rs.overlays.default
          (self: super: {
            deploy-rs = {
              inherit (inputs.deploy-rs.packages.${self.stdenv.hostPlatform.system}) deploy-rs;
              lib = super.deploy-rs.lib;
            };
          })
        ];
      };

      mkDeployNode = hostname: {
        hostname = "${hostname}.build";
        profiles.system = {
          path = deployPkgs.deploy-rs.lib.activate.nixos inputs.self.nixosConfigurations.${hostname};
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
        fern = mkHost "fern" "x86_64-linux";
        oak = mkHost "oak" "x86_64-linux";
        cedar = mkHost "cedar" "x86_64-linux";
        mangowc = mkHost "mangowc" "x86_64-linux";
      };

      deploy = {
        nodes = {
          fern = mkDeployNode "fern";
          oak = mkDeployNode "oak";
          cedar = mkDeployNode "cedar";
        };
      };

      packages = forEachSystem (
        system:
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          wrappers = pkgs.callPackage ./wrappers { inherit inputs; };
        in
        flattenAttrs {
          vm = {
            fern = mkVm "fern" system;
            oak = mkVm "oak" system;
            cedar = mkVm "cedar" system;
            mango = mkVm "mangowc" system;
          };

          wrapped = wrappers;

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
        }
      );
      # Deploy-rs checks
      checks = forEachSystem (system: inputs.deploy-rs.lib.${system}.deployChecks inputs.self.deploy);
    };
}
