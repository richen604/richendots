{ inputs, ... }:
inputs.wrappers.lib.wrapModule (
  {
    config,
    lib,
    wlib,
    ...
  }:
  let
    tomlFormat = config.pkgs.formats.toml { };
  in
  {
    _class = "wrapper";

    options = {
      settings = lib.mkOption {
        inherit (tomlFormat) type;
        description = "settings for satty";
        default = { };
      };
    };
    config = {
      flags = {
        "-c" = toString (tomlFormat.generate "satty-config" config.settings);
      };
      package = config.pkgs.satty;
    };
  }
)
