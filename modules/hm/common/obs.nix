{
  pkgs,
  config,
  lib,
  ...
}:

/*
  TODO: feat(obs): add plugins
  - source record
  - obs advanced masks
  - source clone
  - move transition?
  - some sort of background blur with nvidia card?
  - capture audio if it doesnt work
*/
let
  cfg = config.modules.common.obs;

  # TODO: feat(obs): fix(obs): contribute to hypr-obs-mouse-follow script (toggle, feature parity with alternatives)
  # Derivation for hypr-obs-mouse-follow script (Wayland/Hyprland compatible)
  hypr-obs-mouse-follow = pkgs.stdenv.mkDerivation {
    pname = "hypr-obs-mouse-follow";
    version = "1.0";

    src = pkgs.fetchFromGitHub {
      owner = "Itz-Hex";
      repo = "hypr-obs-mouse-follow";
      rev = "main";
      sha256 = "sha256-3ydA3uwQNUwyJNNOGxn9sc+yPPMhoTJQ6QQHSarLSio=";
    };

    dontBuild = true;

    installPhase = ''
      mkdir -p $out/share/obs/obs-studio/scripts
      cp hypr_mouse_follow.lua $out/share/obs/obs-studio/scripts/

      # Also install documentation
      mkdir -p $out/share/doc/hypr-obs-mouse-follow
      cp README.md $out/share/doc/hypr-obs-mouse-follow/

      # Install the demo gif for reference
      if [ -f example.gif ]; then
        cp example.gif $out/share/doc/hypr-obs-mouse-follow/
      fi
    '';

    meta = with lib; {
      description = "A Lua script for OBS Studio that pans a scaled Display Capture to follow the mouse cursor on Hyprland";
      homepage = "https://github.com/Itz-Hex/hypr-obs-mouse-follow";
      license = licenses.gpl3Only;
      platforms = platforms.linux;
      maintainers = [ ];
    };
  };
in
{
  options.modules.common.obs = {
    enable = lib.mkEnableOption "obs module";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      #obs things
      v4l-utils # Video4Linux utilities
      hypr-obs-mouse-follow # Wayland/Hyprland compatible mouse follow script
      (wrapOBS {
        plugins = with obs-studio-plugins; [
          wlrobs
          looking-glass-obs
          obs-pipewire-audio-capture
        ];
      })
    ];

    # TODO: feat(obs): add scenes to obs module for declarative configuration (maybe as an option for use in other hosts)
    # OBS Scene Collection paths for manual home.file configuration:
    # Scene collections: ".config/obs-studio/basic/scenes/YourSceneName.json"
    # Global sources: ".config/obs-studio/basic/sources.json"
    # Profiles: ".config/obs-studio/basic/profiles/YourProfileName/"
    #
    # Export from OBS: Scene Collection -> Export
    # Then use home.file.".config/obs-studio/basic/scenes/MyScenes.json".source = ./path/to/exported.json;
  };
}
