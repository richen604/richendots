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
    hostname: system:
    let
      pkgs =
        if hostname == "fern" then
          (import inputs.hydenix.inputs.nixpkgs {
            config.allowUnfree = true;
            overlays = [ inputs.hydenix.overlays.default ];
            inherit system;
          })
        else
          pkgsFor system;
      richenLib = mkLib pkgs;
    in
    lib.nixosSystem {
      inherit pkgs system;
      specialArgs = {
        inputs =
          if (hostname == "fern" || hostname == "oak" || hostname == "cedar") then
            (inputs // inputs.richendots-private.inputs)
          else
            inputs;
        inherit hostname richenLib;
      };
      modules = [
        ./hosts/${hostname}
      ];
    };

  mkVm =
    hostname: system:
    (import ./hosts/vm.nix {
      inherit inputs hostname;
      nixosConfiguration = mkHost hostname system;
    }).config.system.build.vm;

  # main function that generates the richenLib for use elsewhere
  mkLib = pkgs: {
    vars = {
      username = "richen";
    };
    wrappers = import ./wrappers { inherit inputs pkgs; };
    # Add any other custom library functions here
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
