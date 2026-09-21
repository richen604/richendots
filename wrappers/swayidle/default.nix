{ pkgs, richenLib, ... }:

pkgs.callPackage ./_swayidle.nix { inherit richenLib; }
