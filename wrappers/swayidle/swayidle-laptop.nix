{ pkgs, richenLib, ... }:

pkgs.callPackage ./_swayidle.nix {
  inherit richenLib;
  dpmsTimeout = 600;
  suspendTimeout = 1800;
}
