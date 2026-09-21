{
  inputs,
  lib,
  mkLib,
  pkgsFor,
}:
let
  hostVars = import ./host-vars.nix { inherit inputs; };

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
      inherit (hostvars) system;
      specialArgs = {
        inputs = inputs // inputs.richendots-private.inputs;
        inherit (hostvars) hostname;
        inherit richenLib hostvars;
      };

      modules = lib.concatLists [
        (recursiveModules ../profiles/common)

        (lib.optionals (lib.elem (hostvars.profile or null) [
          "desktop"
          "laptop"
        ]) (recursiveModules ../profiles/gui))

        (lib.optionals (hostvars ? profile) (recursiveModules ../profiles/${hostvars.profile}))

        (lib.optionals (builtins.pathExists ../hosts/${hostvars.hostname}) (
          recursiveModules ../hosts/${hostvars.hostname}
        ))

        [
          (inputs.richendots-private.nixosModules.${hostvars.hostname} or { })
        ]
      ];
    };

  mkVm =
    hostvars:
    ((mkHost hostvars).extendModules {
      modules = [ ./vm.nix ];
    }).config.system.build.vm;

  normalNixosConfigurations = lib.mapAttrs (_host: mkHost) hostVars;

  installModules = inputs.richendots-private.nixosModules.install or { };

  installNixosConfigurations = lib.mapAttrs' (
    host: installModule:
    lib.nameValuePair "install-${host}" (
      normalNixosConfigurations.${host}.extendModules {
        modules = [ installModule ];
      }
    )
  ) (lib.intersectAttrs normalNixosConfigurations installModules);
in
{
  inherit
    hostVars
    installNixosConfigurations
    mkHost
    mkVm
    normalNixosConfigurations
    ;

  nixosConfigurations = normalNixosConfigurations // installNixosConfigurations;
}
