{ pkgs, richenLib, ... }:

pkgs.callPackage ./swaylock/_swaylock.nix {
  inherit richenLib;
  fontSize = 120;
  indicatorRadius = 220;
}
