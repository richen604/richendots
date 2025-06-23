{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modules.common.expo-dev;
in
{
  options.modules.common.expo-dev = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Expo development environment";
    };
  };

  config = lib.mkIf cfg.enable {

    home.packages = with pkgs; [
      android-studio
      android-tools
      sdkmanager
    ];
  };
}
