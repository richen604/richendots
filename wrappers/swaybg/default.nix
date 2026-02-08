{
  inputs,
  pkgs,
  ...
}:
let
  swaybgWrapper = pkgs.callPackage ./module.nix { inherit inputs; };

  # this is a hack to ensure the wallpaper is in closure
  wallpaperDrv = pkgs.runCommand "swaybg-wallpaper" { } ''
    mkdir -p $out
    cp ${./wall.png} $out/wall.png
  '';
in
(swaybgWrapper.apply {
  pkgs = pkgs;
  wallpaper.path = "${wallpaperDrv}/wall.png";
  mode = "fill";
  extraPackages = [ wallpaperDrv ];
}).wrapper
