{
  inputs,
  lib,
  mkLib,
  pkgsFor,
}:
let
  hostVars = {
    fern = {
      hostname = "fern";
      system = "x86_64-linux";
      profile = "desktop";
      stateVersion = "26.05";
    };

    oak = {
      hostname = "oak";
      system = "x86_64-linux";
      profile = "laptop";
      stateVersion = "26.05";
    };

    cedar = {
      hostname = "cedar";
      system = "x86_64-linux";
      profile = "server";
      stateVersion = "25.05";
    };
  };

  mkHost =
    hostvars:
    let
      pkgs = pkgsFor hostvars.system;
      richenLib = mkLib pkgs;
      recursiveModules =
        dir:
        richenLib.lib.listFilesRecursiveCond dir (
          filename: lib.hasSuffix ".nix" filename && filename != "default.nix" && !lib.hasPrefix "_" filename
        );
    in
    lib.nixosSystem {
      inherit pkgs;
      system = hostvars.system;
      specialArgs = {
        inputs = inputs // inputs.richendots-private.inputs;
        hostname = hostvars.hostname;
        inherit richenLib hostvars;
      };

      modules =
        recursiveModules ../profiles/common
        ++ lib.optionals (hostvars.profile == "desktop" || hostvars.profile == "laptop") (
          recursiveModules ../profiles/gui
        )
        ++ recursiveModules ../profiles/${hostvars.profile}
        ++ recursiveModules ../hosts/${hostvars.hostname}
        ++ [ (inputs.richendots-private.nixosModules.${hostvars.hostname} or { }) ];
    };

  mkVm =
    hostvars:
    (import ./vm.nix {
      inherit inputs;
      nixosConfiguration = mkHost hostvars;
    }).config.system.build.vm;
in
{
  inherit hostVars mkHost mkVm;

  nixosConfigurations = lib.mapAttrs (_host: mkHost) hostVars;
}
