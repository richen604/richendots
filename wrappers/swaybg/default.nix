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
  wallpaper = toString ./wall.png;
  mode = "center";
}).wrapper
