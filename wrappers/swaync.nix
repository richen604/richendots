{ pkgs, richenLib, ... }:

pkgs.callPackage ./swaync/_swaync.nix { inherit richenLib; }
