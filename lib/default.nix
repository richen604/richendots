{ inputs }:
let
  inherit (inputs.nixpkgs) lib;

  nixpkgs = import ./nixpkgs.nix { inherit inputs; };
  inherit (nixpkgs) forEachSystem pkgsFor;

  mkLib =
    pkgs:
    let
      selfLib = {
        vars = import ./vars.nix { inherit inputs lib; };

        lib =
          let
            helpers = import ./helpers.nix { inherit lib; };
          in
          helpers
          // {
            wrapPackage = import ./wrap-package.nix {
              inherit helpers lib pkgs;
            };
          };

        wrappers = import ./wrappers.nix {
          inherit inputs lib pkgs;
          richenLib = selfLib;
        };
      };
    in
    selfLib;

  hosts = import ./hosts.nix {
    inherit
      inputs
      lib
      mkLib
      pkgsFor
      ;
  };

  packages = import ./flake-packages.nix {
    inherit
      forEachSystem
      lib
      mkLib
      pkgsFor
      ;
    inherit (hosts) hostVars mkVm;
  };

  devShell = import ./dev-shell.nix {
    inherit forEachSystem pkgsFor;
  };

  nixpull = import ./nixpull.nix {
    inherit inputs lib;
    inherit (hosts) nixosConfigurations;
  };
in
{
  inherit
    devShell
    forEachSystem
    mkLib
    nixpull
    packages
    pkgsFor
    ;

  inherit (hosts)
    hostVars
    mkHost
    mkVm
    nixosConfigurations
    ;
}
