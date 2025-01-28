{ pkgs, ... }:
{
  home.packages = with pkgs; [
    #obs things
    v4l-utils # Video4Linux utilities
    (wrapOBS {
      plugins = with obs-studio-plugins; [
        obs-nvfbc
        wlrobs
        looking-glass-obs
        obs-pipewire-audio-capture
      ];
    })
  ];
}
