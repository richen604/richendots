{ pkgs, richenLib, ... }:

pkgs.callPackage ./waybar/_waybar.nix {
  inherit richenLib;
  mangoPackage = richenLib.wrappers.mango-oak;
  laptop = true;
}
