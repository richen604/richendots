{ pkgs, richenLib, ... }:

richenLib.lib.wrapPackage {
  package = pkgs.wlsunset;
  args = [
    "-l"
    "49.2"
    "-L"
    "-123.1"
    "-t"
    "3200"
    "-d"
    "60"
    "$@"
  ];
}
