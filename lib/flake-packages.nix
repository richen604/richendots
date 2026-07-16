{
  forEachSystem,
  hostVars,
  lib,
  mkLib,
  mkVm,
  pkgsFor,
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
)
