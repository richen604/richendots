{
  inputs,
  lib,
  pkgs,
  richenLib,
}:
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
        inherit inputs;
        inherit richenLib;
      }
    )
  ) files
)
