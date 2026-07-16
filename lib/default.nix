{ inputs }:
let
  inherit (inputs.nixpkgs) lib;

  packageLib = import ./packages.nix { inherit inputs lib; };
  inherit (packageLib) forEachSystem pkgsFor;

  mkLib =
    pkgs:
    let
      selfLib = {
        vars = import ./vars.nix { inherit inputs lib; };

        lib = import ./core.nix { inherit lib pkgs; };

        wrappers = packageLib.mkWrappers {
          inherit pkgs;
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

  packages = packageLib.mkPackages {
    inherit (hosts) hostVars mkVm;
    inherit mkLib;
  };

  nixpull = import ./nixpull.nix {
    inherit inputs lib;
    inherit (hosts) nixosConfigurations;
  };
in
{
  inherit
    forEachSystem
    mkLib
    nixpull
    packages
    pkgsFor
    ;

  devShell = packageLib.devShell;

  inherit (hosts)
    hostVars
    mkHost
    mkVm
    nixosConfigurations
    ;
}
