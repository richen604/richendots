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
        description = "Path to the mango configuration file.";
      };
    };

    config = {
      filesToPatch = [
        "share/wayland-sessions/mango.desktop"
      ];
      flags = {
        "-c" = toString config."config.conf".path;
      };
      package = config.pkgs.mangowc;
    };
  }
)
