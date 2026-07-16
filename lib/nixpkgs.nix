{ inputs }:
let
  inherit (inputs.nixpkgs) lib;

  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  overlays = import ./overlays.nix { inherit inputs; };
in
{
  inherit systems overlays;

  forEachSystem = f: lib.genAttrs systems f;

  pkgsFor =
    system:
    import inputs.nixpkgs {
      inherit system overlays;
      config = {
        allowUnfree = true;
        permittedInsecurePackages = [
          "olivetin-2025.11.25"
        ];
      };
    };
}
