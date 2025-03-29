{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.modules.easyeffects;
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;

  # Common presets from the community
  perfectEq = builtins.fetchurl {
    url = "https://raw.githubusercontent.com/JackHack96/EasyEffects-Presets/master/Perfect%20EQ.json";
    name = "perfect-eq.json";
    sha256 = "sha256:0cppf5kcpp2spz7y38n0xwj83i4jkgvcbp06p1l005p2vs7xs59f";
  };
in
{
  options.modules.easyeffects = {
    enable = mkEnableOption "EasyEffects audio effects";
  };

  config = mkIf cfg.enable {
    # Install EasyEffects
    home.packages = with pkgs; [
      easyeffects
      calf # Additional audio plugins
      lsp-plugins # More audio plugins
    ];

    # Enable EasyEffects service
    services.easyeffects = {
      enable = true;
      preset = "Perfect EQ"; # Default to Perfect EQ preset
    };

    # Install community presets
    xdg.configFile = {
      "easyeffects/output/Perfect EQ.json".source = perfectEq;
    };
  };
}
