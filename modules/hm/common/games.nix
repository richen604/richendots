{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.common.games;
in
{
  options.modules.common.games = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable games";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      prismlauncher
      # Common Java packages used by Minecraft
      jdk17
      # Performance mods often need these
      gcc
      glibc

      steam-run
      protontricks
      winetricks
      protonup-qt
    ];
  };
}
