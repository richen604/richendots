{ inputs, ... }:
# todo: mango module: autostart.sh option
# todo: mango module: rfc42 compliance, settings + configFile option
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
        description = "Path to the mango configuration file.";
      };
      configFile = lib.mkOption {
        # cheating here so we can use an "impure" path
        # type = wlib.types.file config.pkgs;
        default = config."config.conf".path;
        description = "Path to the mango config file to be used instead of the default one.";
      };
    };

    config = {
      filesToPatch = [
        "share/wayland-sessions/mango.desktop"
      ];
      flags = {
        "-c" = toString config.configFile;
      };
      package = config.pkgs.mangowc;
    };
  }
)
