{ inputs, ... }:
inputs.wrappers.lib.wrapModule (
  {
    config,
    lib,
    wlib,
    pkgs,
    ...
  }:
  let
    /*
      useful envs for vicinae
      USE_LAYER_SHELL = "1";
      QT_SCALE_FACTOR = "1.5";
    */

    jsonFormat = config.pkgs.formats.json { };
    tomlFormat = config.pkgs.formats.toml { };
    themeFiles = lib.mapAttrsToList (name: value: {
      name = name;
      path = tomlFormat.generate "vicinae-theme-${name}" value;
    }) config.themes;
    themesPackage = config.pkgs.runCommand "vicinae-custom-themes" { } ''
      mkdir -p $out/share/vicinae/themes
      ${lib.concatMapStringsSep "\n" (theme: ''
        cp ${theme.path} $out/share/vicinae/themes/${theme.name}.toml
      '') themeFiles}
    '';
  in
  {
    _class = "wrapper";

    options = {
      settings = lib.mkOption {
        inherit (jsonFormat) type;
        description = "Settings written as JSON";
        default = { };
        example = lib.literalExpression ''
          # nix
          {
            close_on_focus_loss = true;
            consider_preedit = true;
            pop_to_root_on_close = true;
            favicon_service = "twenty";
            search_files_in_root = true;
            font = {
              normal = {
                size = 12;
                normal = "Maple Nerd Font";
              };
            };
            theme = {
              light = {
                name = "vicinae-light";
                icon_theme = "default";
              };
              dark = {
                name = "vicinae-dark";
                icon_theme = "default";
              };
            };
            launcher_window = {
              opacity = 0.98;
            };
          }
        '';
      };
      themes = lib.mkOption {
        inherit (tomlFormat) type;
        description = ''
          Theme settings to add to the themes folder. See <https://docs.vicinae.com/theming/getting-started> for supported values.
          The attribute name of the theme will be the name of theme file
        '';
        default = { };
        example = lib.literalExpression ''
          # nix
          {
            catppuccin-mocha = {
              meta = {
                version = 1;
                name = "Catppuccin Mocha";
                description = "Cozy feeling with color-rich accents";
                variant = "dark";
                icon = "icons/catppuccin-mocha.png";
                inherits = "vicinae-dark";
              };

              colors = {
                core = {
                  background = "#1E1E2E";
                  foreground = "#CDD6F4";
                  secondary_background = "#181825";
                  border = "#313244";
                  accent = "#89B4FA";
                };
                accents = {
                  blue = "#89B4FA";
                  green = "#A6E3A1";
                  magenta = "#F5C2E7";
                  orange = "#FAB387";
                  purple = "#CBA6F7";
                  red = "#F38BA8";
                  yellow = "#F9E2AF";
                  cyan = "#94E2D5";
                };
              };
            };
          }
        '';
      };
      configFile = lib.mkOption {
        type = wlib.types.file config.pkgs;
        description = "Path to a custom vicinae configuration file. This will override the settings option.";
        default.path = jsonFormat.generate "custom-vicinae-config" config.settings;
      };
      # todo: implement extensions for vicinae
      # todo: add input for extensions repo to support named extensions
      extensions = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        description = ''
          List of Vicinae extensions to install.
          You can use the `mkVicinaeExtension` function from the overlay to create extensions.
        '';
        default = [ ];
      };
    };
    config =
      let
        # vicinae only supports passing a configuration file to the server command
        vicinaeWrapper = config.pkgs.writeShellScriptBin "vicinae" ''
          if [[ "''${1:-}" == "server" ]]; then
            exec ${lib.getExe' config.package "vicinae"} server --config "${config.configFile.path}" "''${@:2}"
          else
            exec ${lib.getExe' config.package "vicinae"} "$@"
          fi
        '';
      in
      {
        package = config.pkgs.vicinae;
        extraPackages = [ vicinaeWrapper ];
        filesToPatch = [
          "share/systemd/user/vicinae.service"
        ];

        env = lib.optionalAttrs (themeFiles != [ ]) {
          # we need to add custom themes dir to XDG_DATA_DIRS
          XDG_DATA_DIRS = "$XDG_DATA_DIRS:${themesPackage}/share";
        };
      };
  }
)
