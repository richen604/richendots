{
  inputs,
  pkgs,
  lib,
  ...
}:
let
  mangoWrapper = pkgs.callPackage ./module.nix { inherit inputs; };
in
(mangoWrapper.apply {
  pkgs = pkgs;
  "config.conf".content = builtins.readFile ./config.conf;
}).wrapper
