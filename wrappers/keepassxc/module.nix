{ inputs, ... }:
inputs.wrappers.lib.wrapModule (
  {
    config,
    lib,
    wlib,
    ...
  }:
  # todo: for browser integration, you have to run `nix run nixpkgs#keepassxc` once and select the browsers you want. for some reason the browser selection is not part of the configuration file
  let
    iniFmt = config.pkgs.formats.ini { };
  in
  {
    _class = "wrapper";

    options = {
      settings = lib.mkOption {
        inherit (iniFmt) type;
        description = ''
          configuration of keepassxc
          its better you run keepassxc once, select settings, then see the generated ini
          see https://github.com/keepassxreboot/keepassxc/blob/develop/src/core/Config.cpp for options
        '';
        default = { };
      };
      configFile = lib.mkOption {
        type = wlib.types.file config.pkgs;
        description = "keepassxc configuration file";
        default.path = iniFmt.generate "keepassxc.ini" config.settings;
      };
    };
    config = {
      flags = {
        "--config" = toString config.configFile.path;
      };
      package = config.pkgs.keepassxc;
    };
  }
)
