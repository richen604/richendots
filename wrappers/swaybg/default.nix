{
  inputs,
  pkgs,
  ...
}:
let
  swaybgWrapper = pkgs.callPackage ./module.nix { inherit inputs; };
in
(swaybgWrapper.apply {
  pkgs = pkgs;
  wallpaper.path = ./wall.png;
  mode = "fill";
}).wrapper
