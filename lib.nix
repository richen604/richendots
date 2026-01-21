{ inputs }:
let
  inherit (inputs.nixpkgs) lib;

  pkgsFor =
    system:
    import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };

  forEachSystem =
    f:
    lib.genAttrs [
      "x86_64-linux"
      "aarch64-linux"
    ] (system: f system);

  mkHost =
    hostvars:
    let
      pkgs =
        if hostvars.hostname == "fern" then
          (import inputs.hydenix.inputs.nixpkgs {
            config.allowUnfree = true;
            overlays = [ inputs.hydenix.overlays.default ];
            system = hostvars.system;
          })
        else
          pkgsFor hostvars.system;
      richenLib = mkLib pkgs;
    in
    lib.nixosSystem {
      system = hostvars.system;
      inherit pkgs;
      specialArgs = {
        inputs = (inputs // inputs.richendots-private.inputs);
        hostname = hostvars.hostname;
        inherit richenLib;
      };
      modules = [
        ./hosts/${hostvars.hostname}
        ./profiles/common.nix
        ./profiles/${hostvars.profile}.nix
        inputs.richendots-private.nixosModules.${hostvars.hostname} or { }
      ];
    };

  mkVm =
    hostvars:
    (import ./hosts/vm.nix {
      inherit inputs;
      nixosConfiguration = mkHost {
        hostname = hostvars.hostname;
        system = hostvars.system;
        profile = hostvars.profile;
      };
    }).config.system.build.vm;

  mkLib = pkgs: {
    vars = {
      username = "richen";
    };
    wrappers = import ./wrappers { inherit inputs pkgs; };
    lib = { };
  };
in
{
  inherit
    pkgsFor
    forEachSystem
    mkHost
    mkVm
    mkLib
    ;
}
