{
  hostVars,
  inputs,
  lib,
  mkLib,
  pkgsFor,
}:
let
  privateInput = inputs.richendots-private or { };
  privateProfiles = privateInput.moduleRoots.profiles or { };
  privateHosts = privateInput.moduleRoots.hosts or { };

  mkHost =
    hostvars:
    let
      pkgs = pkgsFor hostvars.system;
      richenLib = mkLib pkgs hostvars;
      recursiveModules =
        dir:
        richenLib.lib.listFilesRecursiveCond dir (
          filename: lib.hasSuffix ".nix" filename && filename != "default.nix" && !lib.hasPrefix "_" filename
        );
      privateProfileRoots = lib.concatMap (
        profile: lib.optional (builtins.hasAttr profile privateProfiles) privateProfiles.${profile}
      ) hostvars.profiles;
      moduleRoots =
        map (profile: ../profiles/${profile}) hostvars.profiles
        ++ privateProfileRoots
        ++ lib.optional (builtins.pathExists ../hosts/${hostvars.hostname}) ../hosts/${hostvars.hostname}
        ++ lib.optional (builtins.hasAttr hostvars.hostname privateHosts) privateHosts.${hostvars.hostname};
    in
    lib.nixosSystem {
      inherit pkgs;
      inherit (hostvars) system;
      specialArgs = {
        inputs = inputs // (privateInput.inputs or { });
        inherit (hostvars) hostname;
        inherit richenLib hostvars;
      };

      modules = lib.concatMap recursiveModules moduleRoots;
    };

  mkVm =
    hostvars:
    ((mkHost hostvars).extendModules {
      modules = [ ./vm.nix ];
    }).config.system.build.vm;

  normalNixosConfigurations = lib.mapAttrs (_host: mkHost) hostVars;

  installModules = privateInput.nixosModules.install or { };

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
