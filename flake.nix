{
  description = "template for hydenix";

  inputs = {
    nixpkgs.follows = "hydenix/nixpkgs";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    hydenix = {
      url = "github:richen604/hydenix";
      # url = "path:/home/richen/newdev/hydenix";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    richendots-private = {
      url = "git+ssh://git@github.com/richen604/richendots-private.git?ref=main";
      # url = "path:/home/richen/newdev/richendots-private";
    };

    wrappers.url = "github:lassulus/wrappers";
    hjem = {
      url = "github:feel-co/hjem";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs =
    { ... }@inputs:
    let
      richenLib = import ./lib.nix { inherit inputs; };
    in
    {
      nixosConfigurations = {
        fern = richenLib.mkHost {
          hostname = "fern";
          system = "x86_64-linux";
          profile = "desktop";
        };
        oak = richenLib.mkHost {
          hostname = "oak";
          system = "x86_64-linux";
          profile = "laptop";
        };
        cedar = richenLib.mkHost {
          hostname = "cedar";
          system = "x86_64-linux";
          profile = "server";
        };
        mangowc = richenLib.mkHost {
          hostname = "mangowc";
          system = "x86_64-linux";
          profile = "desktop";
        };
      };

      packages = richenLib.forEachSystem (
        system:
        let
          pkgs = richenLib.pkgsFor system;
          _richenLib = richenLib.mkLib pkgs;
          wrappers = _richenLib.wrappers;
        in
        {
          vm-fern = richenLib.mkVm {
            hostname = "fern";
            system = system;
            profile = "desktop";
          };
          vm-oak = richenLib.mkVm {
            hostname = "oak";
            system = system;
            profile = "laptop";
          };
          vm-cedar = richenLib.mkVm {
            hostname = "cedar";
            system = system;
            profile = "server";
          };
          vm-mango = richenLib.mkVm {
            hostname = "mangowc";
            system = system;
            profile = "desktop";
          };
        }
        // wrappers
      );

      devShells = richenLib.forEachSystem (
        system:
        let
          pkgs = richenLib.pkgsFor system;
          _richenLib = richenLib.mkLib pkgs;
          wrappers = _richenLib.wrappers;
        in
        {
          wrappers = pkgs.mkShellNoCC {
            allowSubstitutes = false;
            packages = builtins.attrValues wrappers;
          };
        }
      );

      nixConfig = {
        extra-substituters = [
          "https://cache.nixos.org?priority=10"
        ];
        extra-trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        ];
      };
    };
}
