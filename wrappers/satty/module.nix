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

      configFile = lib.mkOption {
        type = wlib.types.file config.pkgs;
        default.path = tomlFormat.generate "satty-config" config.settings;
        description = "Path to a custom TOML configuration file for satty. Overrides settings option.";
      };
    };
    config = {
      flags = {
        "-c" = toString config.configFile.path;
      };
      package = config.pkgs.satty;
    };
  }
)
