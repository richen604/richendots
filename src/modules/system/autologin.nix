{
  config,
  lib,
  userConfig,
  ...
}:

{
  options.modules.autologin = {
    enable = lib.mkEnableOption "autologin";
  };
  config = lib.mkIf config.modules.autologin.enable {
    services = {
      displayManager = {
        sddm = {
          enable = true;
          wayland.enable = true;
          settings = {
            Autologin = {
              Session = "hyprland.desktop";
              User = userConfig.username;
            };
          };
        };
        defaultSession = "hyprland";
      };
    };
  };
}
