{
  config,
  lib,
  ...
}:

let
  cfg = config.modules.autologin;
in
{
  options.modules.autologin = {
    enable = lib.mkEnableOption "autologin";
  };
  config = lib.mkIf cfg.enable {
    services = {
      displayManager = {
        sddm = {
          enable = true;
          wayland.enable = true;
          settings = {
            Autologin = {
              Session = "hyprland.desktop";
              User = "richen";
            };
          };
        };
        defaultSession = "hyprland";
      };
    };
  };
}
