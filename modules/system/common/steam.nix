{
  pkgs,
  config,
  lib,
  ...
}:

let
  cfg = config.modules.steam;
in
{
  options.modules.steam = {
    enable = lib.mkEnableOption "steam";
  };

  config = lib.mkIf cfg.enable {

    environment.sessionVariables = {
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = "$HOME/.steam/root/compatibilitytools.d";
    };

    programs = {
      steam = {
        enable = true;
        remotePlay.openFirewall = true;
        gamescopeSession.enable = true;
        protontricks.enable = true;
      };
    };

    environment.systemPackages = with pkgs; [
      mangohud
      gamescope
      # Additional packages for Wayland/Vulkan support
      wayland
      wayland-protocols
      vulkan-loader
      vulkan-validation-layers
    ];
  };
}
