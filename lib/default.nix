{ inputs }:
let
  inherit (inputs.nixpkgs) lib;

  hostVars = import ./host-vars.nix { inherit inputs; };

  packageLib = import ./packages.nix { inherit inputs lib; };
  inherit (packageLib) forEachSystem pkgsFor;

  mkLib =
    pkgs: hostVars:
    let
      selfLib = {
        inherit hostVars;

        vars = import ./vars.nix { inherit inputs lib; };

        theme = import ./theme { inherit (selfLib) vars; };

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
      hostVars
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
    nixosConfigurations = hosts.normalNixosConfigurations;
  };

  lintChecks = import ./checks.nix {
    inherit
      inputs
      lib
      forEachSystem
      pkgsFor
      ;
  };

  checks = lintChecks;
in
{
  inherit
    checks
    forEachSystem
    mkLib
    nixpull
    packages
    pkgsFor
    ;

  inherit (packageLib) devShell;

  inherit (nixpull) deployChecks;

  inherit (hosts)
    hostVars
    mkHost
    mkVm
    nixosConfigurations
    ;
}
