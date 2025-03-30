{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.modules.gamescope;
in
{
  options.modules.gamescope = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable gamescope";
    };
  };

  config = mkIf cfg.enable {

    # Add capability settings for gamescope
    security.wrappers.gamescope = {
      owner = "root";
      group = "root";
      capabilities = "cap_sys_nice+ep";
      source = "${pkgs.gamescope}/bin/gamescope";
    };
  };
}
