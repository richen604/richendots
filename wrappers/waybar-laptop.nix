{ pkgs, richenLib, ... }:

pkgs.callPackage ./waybar/_waybar-laptop.nix { inherit richenLib; }
