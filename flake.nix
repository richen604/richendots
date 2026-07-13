{
  description = "template for hydenix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    richendots-private = {
      #url = "git+ssh://git@github.com/richen604/richendots-private.git?ref=main";
      url = "path:/mnt/dev/richendots-private";
      inputs.nixarr.inputs.nixpkgs.follows = "nixpkgs";
      inputs.sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    };
    mango = {
      url = "github:DreamMaoMao/mango/main";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    mnw.url = "github:Gerg-L/mnw";
    wrappers = {
      url = "github:lassulus/wrappers";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
