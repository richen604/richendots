{ inputs, ... }:
inputs.wrappers.lib.wrapModule (
  {
    config,
    lib,
    pkgs,
    wlib,
    ...
  }:
  {
    _class = "wrapper";

    options = {
      "config.conf" = lib.mkOption {
        type = wlib.types.file config.pkgs;
        default.content = "";
        description = "path to the mango configuration file.";
      };

      configFile = lib.mkOption {
        type = wlib.types.file config.pkgs;
        default.path = config."config.conf".path;
        description = "path to the mango config file to be used instead of the default one.";
      };
    };

    config = {
      filesToPatch = [
        "share/wayland-sessions/mango.desktop"
      ];
      flags = {
        "-c" = toString config.configFile.path;
      };
      package = config.pkgs.mangowc;
    };
  }
)
