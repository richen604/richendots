{
  pkgs,
  richenLib,
  ...
}:
richenLib.lib.wrapPackage {
  package = pkgs.swaybg;
  flags = {
    "-i" = "${./wall.png}";
    "-m" = "fill";
  };
}
