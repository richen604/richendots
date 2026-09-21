{ pkgs, richenLib, ... }:

pkgs.callPackage ./swaylock/_swaylock.nix { inherit richenLib; }
