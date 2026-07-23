{
  inputs,
  pkgs,
  richenLib,
  ...
}:
let
  equibopTheme = import ./config/equibop/_theme.nix { theme = richenLib.theme; };
  spicetifyManaged = import ./config/spicetify/_managed.nix {
    inherit pkgs;
    theme = richenLib.theme;
  };
  equibopCss = pkgs.replaceVars ./config/equibop/system24-grove.css equibopTheme.replacements;
in
{
  imports = [
    inputs.hjem.nixosModules.default
  ];

  hjem = {
    users.${richenLib.vars.username} = {
      user = richenLib.vars.username;
      directory = "/home/${richenLib.vars.username}";
      clobberFiles = true;
      files = {
        ".config/spicetify/config-xpui.ini" = {
          type = "copy";
          permissions = "0644";
          source = spicetifyManaged.config;
        };
        ".config/spicetify/CustomApps/marketplace/extension.js" = {
          type = "copy";
          permissions = "0644";
          source = ./config/spicetify/CustomApps/marketplace/extension.js;
        };
        ".config/spicetify/CustomApps/marketplace/index.js" = {
          type = "copy";
          permissions = "0644";
          source = ./config/spicetify/CustomApps/marketplace/index.js;
        };
        ".config/spicetify/CustomApps/marketplace/manifest.json" = {
          type = "copy";
          permissions = "0644";
          source = ./config/spicetify/CustomApps/marketplace/manifest.json;
        };
        ".config/spicetify/CustomApps/marketplace/style.css" = {
          type = "copy";
          permissions = "0644";
          source = ./config/spicetify/CustomApps/marketplace/style.css;
        };
        ".config/spicetify/Themes/tui/color.ini" = {
          type = "copy";
          permissions = "0644";
          source = spicetifyManaged.colorIni;
        };
        ".config/spicetify/Themes/tui/user.css" = {
          type = "copy";
          permissions = "0644";
          source = spicetifyManaged.userCss;
        };
        ".config/equibop/themes/system24-grove.css" = {
          type = "copy";
          permissions = "0644";
          source = equibopCss;
        };
      };
    };
  };
}
