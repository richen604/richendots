{ pkgs, richenLib, ... }:

pkgs.callPackage ./_vicinae.nix {
  inherit richenLib;
  qtScaleFactor = "1.2";
}
