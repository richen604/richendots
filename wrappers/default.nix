{inputs, pkgs, richenLib, ...}:

let
  callPackage = pkgs.lib.callPackageWith (pkgs // { inherit inputs richenLib; });
in
{
  kitty = callPackage ./kitty.nix {};
  mango = callPackage ./mango.nix {};
  swaybg = callPackage ./swaybg.nix {};
  zsh = callPackage ./zsh.nix {};
  modules = {
    kitty = callPackage ./kitty/module.nix {};
    mango = callPackage ./mango/module.nix {};
    swaybg = callPackage ./swaybg/module.nix {};
    zsh = callPackage ./zsh/module.nix {};
  };
}
