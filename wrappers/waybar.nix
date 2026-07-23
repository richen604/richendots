{ pkgs, richenLib, ... }:

pkgs.callPackage ./waybar/_waybar.nix { inherit richenLib; }
