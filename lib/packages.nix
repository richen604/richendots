{ inputs, lib }:
let
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  overlays = [
    (final: prev: {
      waybar = (prev.waybar.override { cavaSupport = false; }).overrideAttrs (_old: {
        version = "0.16.0-unstable-2026-07-12";
        src = final.fetchFromGitHub {
          owner = "Alexays";
          repo = "Waybar";
          rev = "cf19c836d3dafc1646bb60a49269d981623b680a";
          hash = "sha256-h1ZmLmqBkm3MyShV6p83kBtpeLa9rnZUVz75kp+0Ccw=";
        };
        buildInputs = _old.buildInputs ++ [ final.modemmanager ];
        doInstallCheck = false;
      });
    })
  ];

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

  mkWrappers =
    { pkgs, richenLib }:
    let
      nameFromPath =
        path:
        let
          base = lib.removeSuffix ".nix" (baseNameOf path);
        in
        if base == "default" then baseNameOf (dirOf path) else base;

      files = richenLib.lib.listFilesRecursiveCond ../wrappers (
        filename:
        lib.hasSuffix ".nix" filename && filename != "module.nix" && lib.hasPrefix "_" filename == false
      );
    in
    lib.listToAttrs (
      map (
        path:
        lib.nameValuePair (nameFromPath path) (
          pkgs.callPackage path {
            inherit inputs richenLib;
          }
        )
      ) files
    );

  mkPackages =
    {
      hostVars,
      mkLib,
      mkVm,
    }:
    forEachSystem (
      system:
      let
        pkgs = pkgsFor system;
        richenLib = mkLib pkgs;
        vmPackages = lib.mapAttrs' (
          name: hostvars: lib.nameValuePair "vm-${name}" (mkVm (hostvars // { inherit system; }))
        ) hostVars;
      in
      vmPackages // richenLib.wrappers
    );

  devShell = forEachSystem (
    system:
    let
      pkgs = pkgsFor system;
    in
    pkgs.mkShellNoCC {
      allowSubstitutes = false;
      packages = with pkgs; [
        deadnix
        git
        hyperfine
        nil
        nixfmt
        statix
      ];
    }
  );
in
{
  inherit
    devShell
    forEachSystem
    mkPackages
    mkWrappers
    overlays
    pkgsFor
    systems
    ;
}
