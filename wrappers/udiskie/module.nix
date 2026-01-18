{ inputs, ... }:
inputs.wrappers.lib.wrapModule (
  {
    config,
    lib,
    wlib,
    ...
  }:
  # note this requires services.udisks2.enable = true; in nixos config
  let
    yamlFormat = config.pkgs.formats.yaml { };
  in
  {
    _class = "wrapper";

    options = {
      settings = lib.mkOption {
        inherit (yamlFormat) type;
        description = ''
          udiskie settings written as YAML";
          https://raw.githubusercontent.com/coldfix/udiskie/master/doc/udiskie.8.txt
        '';

        default = { };
      };
      configFile = lib.mkOption {
        type = wlib.types.file config.pkgs;
        description = "The generated udiskie configuration file.";
        default.path = yamlFormat.generate "udiskie-config.yml" config.settings;
      };
      flags = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        description = "Additional command line flags for udiskie.";
        default = { };
      };
    };

    config = {
      package = config.pkgs.udiskie;
      flags = {
        "-c" = toString config.configFile.path;
      }
      // config.flags;
    };
  }
)
