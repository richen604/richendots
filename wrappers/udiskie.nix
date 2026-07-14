{
  pkgs,
  richenLib,
  ...
}:
let
  config = (pkgs.formats.yaml { }).generate "udiskie-config" {
    program_options = {
      tray = true;
      automount = true;
      notify = true;
    };
  };
in
richenLib.lib.wrapPackage {
  package = pkgs.udiskie;
  exePath = "${pkgs.udiskie}/bin/udiskie";
  flagSeparator = "=";
  flags."--config" = config;
  passthru.config.path = config;
}
