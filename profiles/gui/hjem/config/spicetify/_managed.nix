{ pkgs, theme }:
let
  spicetifyTheme = import ./_theme.nix {
    inherit (pkgs) lib;
    inherit theme;
  };
  formatIniSection = name: attrs: ''
    [${name}]
    ${pkgs.lib.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (key: value: "${key} = ${value}") attrs)}
  '';
  generatedColorSection = pkgs.writeText "spicetify-generated-colors.ini" (
    "\n"
    + pkgs.lib.concatStringsSep "\n" (pkgs.lib.mapAttrsToList formatIniSection spicetifyTheme.colorIni)
  );
  colorIni = pkgs.concatText "spicetify-color.ini" [
    ./Themes/tui/color.ini
    generatedColorSection
  ];
  config = pkgs.replaceVars ./config-xpui.ini {
    "spicetify-color-scheme" = spicetifyTheme.colorScheme;
  };
  userCss = ./Themes/tui/user.css;
  bundle = pkgs.linkFarm "spicetify-managed-${theme.name}" [
    {
      name = "color.ini";
      path = colorIni;
    }
    {
      name = "config-xpui.ini";
      path = config;
    }
    {
      name = "user.css";
      path = userCss;
    }
  ];
in
{
  inherit
    bundle
    colorIni
    config
    userCss
    ;
}
