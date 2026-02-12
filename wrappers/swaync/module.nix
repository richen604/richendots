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
      configFile = lib.mkOption {
        type = wlib.types.file config.pkgs;
        default.path = jsonFormat.generate "swaync-config" config.settings;
        description = "Path to a custom JSON configuration file for swaync. Overrides settings option.";
      };
      "style.css" = lib.mkOption {
        type = wlib.types.file config.pkgs;
        default.content = "";
        description = "Path to a custom CSS file for swaync.";
      };
    };

    config = {
      filesToPatch = [
        "share/systemd/user/swaync.service"
      ];
      package = config.pkgs.swaynotificationcenter;
      flags = {
        "-c" = toString config.configFile.path;
        "-s" = toString config."style.css".path;
      };
    };
  }
)
