{
  inputs,
  pkgs,
  richenLib,
  ...
}:

let
  # TODO: modules should have their own callPackage context matching inputs.wrappers syntax
  callPackage = pkgs.lib.callPackageWith (pkgs // { inherit inputs richenLib; });
in
{
  kitty = callPackage ./kitty.nix { };
  mango = callPackage ./mango.nix { };
  satty = callPackage ./satty.nix { };
  swaybg = callPackage ./swaybg.nix { };
  swaync = callPackage ./swaync.nix { };
  zsh = callPackage ./zsh.nix { };
  waybar = callPackage ./waybar.nix { };
  vicinae = callPackage ./vicinae.nix { };
  modules = {
    kitty = callPackage ./kitty/module.nix { };
    mango = callPackage ./mango/module.nix { };
    satty = callPackage ./satty/module.nix { };
    swaybg = callPackage ./swaybg/module.nix { };
    swaync = callPackage ./swaync/module.nix { };
    zsh = callPackage ./zsh/module.nix { };
    waybar = callPackage ./waybar/module.nix { };
    vicinae = callPackage ./vicinae/module.nix { };
  };
}
