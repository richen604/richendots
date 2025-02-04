{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.modules.obsidian;
in
{
  options.modules.obsidian = {
    enable = mkEnableOption "obsidian module";
    # TODO: add backup methods
    backupPaths = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Full paths for Obsidian backup locations";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      obsidian
    ];

  };
}
