{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.modules.kdeconnect;
in
{
  options.modules.kdeconnect = {
    enable = mkEnableOption "KDE Connect";
  };

  config = mkIf cfg.enable {
    services.kdeconnect.enable = true;
    services.kdeconnect.indicator = true;

    # TODO: setup auto clipboard on my android phone https://askubuntu.com/a/1519058
  };
}
