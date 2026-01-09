{ inputs, ... }:
inputs.wrappers.lib.wrapModule (
  {
    config,
    lib,
    wlib,
    ...
  }:
  let
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
          #nix
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
      envVar = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        description = "List of environment variables to set for Vicinae.";
        default = { };
        example = {
          USE_LAYER_SHELL = "1";
          QT_SCALE_FACTOR = "1.5";
        };
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
    config = {
      package = config.pkgs.vicinae;
      env =
        config.envVar
        // {
          XDG_CONFIG_HOME = toString (
            config.pkgs.linkFarm "vicinae-xdg-config" [
              {
                name = "vicinae/settings.json";
                path = jsonFormat.generate "vicinae-settings" config.settings;
              }
            ]
          );
        }
        // lib.optionalAttrs (themeFiles != [ ]) {
          # we need to add custom themes dir to XDG_DATA_DIRS
          XDG_DATA_DIRS = "${themesPackage}/share";
        };
    };
  }
)
