{
  pkgs,
  richenLib,
  qtScaleFactor ? null,
  ...
}:
let
  vicinaeTheme = import ./_theme.nix { inherit (richenLib) theme; };
  settings = {
    close_on_focus_loss = false;
    consider_preedit = true;
    pop_to_root_on_close = true;
    favicon_service = "twenty";
    search_files_in_root = true;
    theme = {
      light = {
        name = "vicinae-light";
        icon_theme = "Papirus";
      };
      dark = {
        inherit (vicinaeTheme) name;
        icon_theme = "Papirus-Dark";
      };
    };
    font = {
      normal = {
        size = 11;
        family = "GohuFont 11 Nerd Font";
      };
    };
    launcher_window = {
      layer_shell.layer = "overlay";
      compact_mode.enabled = true;
      size = {
        width = 700;
        height = 436;
      };
    };
  };
  config = (pkgs.formats.json { }).generate "custom-vicinae-config" settings;
  themes = {
    ${vicinaeTheme.name} = vicinaeTheme.theme;
  };
  themeFiles = pkgs.lib.mapAttrsToList (name: value: {
    inherit name;
    path = (pkgs.formats.toml { }).generate "vicinae-theme-${name}" value;
  }) themes;
  themesPackage = pkgs.runCommand "vicinae-custom-themes" { } ''
    mkdir -p $out/share/vicinae/themes
    ${pkgs.lib.concatMapStringsSep "\n" (theme: ''
      cp ${theme.path} $out/share/vicinae/themes/${theme.name}.toml
    '') themeFiles}
  '';
in
richenLib.lib.wrapPackage {
  package = pkgs.vicinae;
  filesToPatch = [ "share/systemd/user/vicinae.service" ];
  env = {
    USE_LAYER_SHELL = "1";
    VICINAE_OVERRIDES = config;
    XDG_DATA_DIRS = "$XDG_DATA_DIRS:${themesPackage}/share";
  }
  // pkgs.lib.optionalAttrs (qtScaleFactor != null) {
    QT_SCALE_FACTOR = qtScaleFactor;
  };
  passthru = {
    config.path = config;
    inherit themesPackage;
  };
}
