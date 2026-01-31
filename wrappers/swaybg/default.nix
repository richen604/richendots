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
  wallpaper = ./wall.png;
  mode = "center";
}).wrapper
