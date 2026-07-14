{
  pkgs,
  richenLib,
  ...
}:
let
  wallpaperPkg = pkgs.runCommandLocal "swaybg-wallpaper" { } ''
    mkdir -p $out
    cp ${./wall.png} $out/wall.png
  '';
in
richenLib.lib.wrapPackage {
  package = pkgs.swaybg;
  flags = {
    "-i" = "${wallpaperPkg}/wall.png";
    "-m" = "fill";
  };
}
