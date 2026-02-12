{ inputs, ... }:
inputs.wrappers.lib.wrapModule (
  {
    config,
    lib,
    wlib,
    ...
  }:
  {
    # TODO: extend swaybg wrapper options
    _class = "wrapper";

    options = {
      wallpaper = lib.mkOption {
        type = wlib.types.file config.pkgs;
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
      # hack to ensure wallpaper is in closure
      wallpaperPkg = lib.mkOption {
        type = lib.types.package;
        description = "Package that provides the wallpaper image. this ensures the wallpaper is in the closure.";
        default = config.pkgs.runCommandLocal "swaybg-wallpaper" { } ''
          mkdir -p $out
          cp ${config.wallpaper.path} $out/wall.png
        '';
      };
    };
    config = {
      flags = {
        "-i" = toString config.wallpaperPkg + "/wall.png";
        "-m" = config.mode;
      };
      package = config.pkgs.swaybg;
    };
  }
)
