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
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable autologin";
    };

    user = lib.mkOption {
      type = lib.types.str;
      description = "User to autologin";
    };

    session = lib.mkOption {
      type = lib.types.str;
      description = "Session to autologin";
    };
  };
  config = lib.mkIf cfg.enable {
    services = {
      displayManager = {
        sddm = {
          enable = true;
          wayland.enable = true;
          settings = {
            Autologin = {
              Session = "${cfg.session}.desktop";
              User = cfg.user;
            };
          };
        };
        defaultSession = "${cfg.session}.desktop";
      };
    };
  };
}
