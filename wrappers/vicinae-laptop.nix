{ pkgs, richenLib, ... }:

pkgs.callPackage ./vicinae/_vicinae.nix {
  inherit richenLib;
  qtScaleFactor = "1.2";
}
