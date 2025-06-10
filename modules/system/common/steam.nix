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
      gamemode.enable = true;
      gamemode.enableRenice = true;
      gamemode.settings = {
        general = {
          inhibit_screensaver = 1;
        };

        gpu = {
          apply_gpu_optimisations = "accept-responsibility";
        };

        custom = {
          start = "notify-send 'GameMode started'";
          end = "notify-send 'GameMode ended'";
        };
      };
      steam = {
        enable = true;
        remotePlay.openFirewall = true;
        gamescopeSession.enable = true;
      };
    };

    environment.systemPackages = with pkgs; [
      steam
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
