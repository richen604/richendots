{ pkgs, richenLib, ... }:

pkgs.callPackage ./kitty/_kitty.nix { inherit richenLib; }
