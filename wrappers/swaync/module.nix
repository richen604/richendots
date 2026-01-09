{ inputs, ... }:
inputs.wrappers.lib.wrapModule (
  {
    config,
    lib,
    wlib,
    ...
  }:
  let
    jsonFormat = config.pkgs.formats.json { };
  in
  {
    _class = "wrapper";

    options = {
      settings = lib.mkOption {
        inherit (jsonFormat) type;
        description = "swaync settings written as JSON";
        default = { };
      };
      "style.css" = lib.mkOption {
        type = wlib.types.file config.pkgs;
        default.content = "";
        description = "Path to a custom CSS file for swaync.";
      };
    };

    config = {
      package = config.pkgs.swaynotificationcenter;
      env = {
        XDG_CONFIG_HOME = toString (
          config.pkgs.linkFarm "swaync-config" [
            {
              name = "swaync/config.json";
              path = jsonFormat.generate "swaync-config" config.settings;
            }
            {
              name = "swaync/style.css";
              path = config."style.css".path;
            }
          ]
        );
      };
    };
  }
)
