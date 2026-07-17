{ pkgs, richenLib, ... }:

pkgs.callPackage ./_vicinae.nix { inherit richenLib; }
