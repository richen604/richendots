{
  pkgs,
  config,
  lib,
  ...
}:

let
  cfg = config.modules.common.obs;
in
{
  options.modules.common.obs = {
    enable = lib.mkEnableOption "obs module";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      #obs things
      v4l-utils # Video4Linux utilities
      (wrapOBS {
        plugins = with obs-studio-plugins; [
          wlrobs
          looking-glass-obs
          obs-pipewire-audio-capture
        ];
      })
    ];
  };
}
