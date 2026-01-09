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
    # TODO: extend swaybg wrapper options
    _class = "wrapper";

    options = {
      wallpaper = lib.mkOption {
        type = lib.types.path;
        description = "Path to the wallpaper image.";
        default.path = "";
      };
      mode = lib.mkOption {
        type = lib.types.enum [
          "center"
          "fill"
          "fit"
          "stretch"
          "tile"
        ];
        description = "Wallpaper display mode (e.g., center, fill, fit, stretch, tile).";
        default = "center";
      };
    };
    config = {
      flags = {
        "-i" = toString config.wallpaper;
        "-m" = config.mode;
      };
      package = config.pkgs.swaybg;
    };
  }
)
