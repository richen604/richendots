{
  description = "template for hydenix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    sunshineNixpkgs.url = "github:NixOS/nixpkgs/pull/521906/head";
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    richendots-private = {
      #url = "git+ssh://git@github.com/richen604/richendots-private.git?ref=main";
      url = "path:/mnt/dev/richendots-private";
    };
    mango.url = "github:DreamMaoMao/mango/bb0160d7cf1187f1d3292adbed51d834c6a31471";
    mnw.url = "github:Gerg-L/mnw";
    wrappers.url = "github:lassulus/wrappers";
    hjem = {
      url = "github:feel-co/hjem";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, ... }@inputs:
    let
      richenLib = import ./lib.nix { inherit inputs; };
      nixpull = import ./modules/nixpull/flake-module.nix { inherit inputs self; };
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
        }
        // wrappers
      );

      devShell = richenLib.forEachSystem (
        system:
        let
          pkgs = richenLib.pkgsFor system;
          _richenLib = richenLib.mkLib pkgs;
          wrappers = _richenLib.wrappers;
        in
        pkgs.mkShellNoCC {
          allowSubstitutes = false;
          packages = builtins.attrValues wrappers;
        }
      );
    }
    // nixpull;
}
