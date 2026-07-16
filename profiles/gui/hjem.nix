{ inputs, ... }:
{
  imports = [
    inputs.hjem.nixosModules.default
  ];

  hjem = {
    users.richen = {
      user = "richen";
      directory = "/home/richen";
      clobberFiles = true;
      files = {
        ".config/equibop/themes/system24-grove.css".source = ../config/equibop/system24-grove.css;
        ".config/spicetify/config-xpui.ini" = {
          type = "copy";
          permissions = "0644";
          source = ../config/spicetify/config-xpui.ini;
        };
        ".config/spicetify/CustomApps/marketplace/extension.js" = {
          type = "copy";
          permissions = "0644";
          source = ../config/spicetify/CustomApps/marketplace/extension.js;
        };
        ".config/spicetify/CustomApps/marketplace/index.js" = {
          type = "copy";
          permissions = "0644";
          source = ../config/spicetify/CustomApps/marketplace/index.js;
        };
        ".config/spicetify/CustomApps/marketplace/manifest.json" = {
          type = "copy";
          permissions = "0644";
          source = ../config/spicetify/CustomApps/marketplace/manifest.json;
        };
        ".config/spicetify/CustomApps/marketplace/style.css" = {
          type = "copy";
          permissions = "0644";
          source = ../config/spicetify/CustomApps/marketplace/style.css;
        };
        ".config/spicetify/Themes/tui/color.ini" = {
          type = "copy";
          permissions = "0644";
          source = ../config/spicetify/Themes/tui/color.ini;
        };
        ".config/spicetify/Themes/tui/user.css" = {
          type = "copy";
          permissions = "0644";
          source = ../config/spicetify/Themes/tui/user.css;
        };
      };
    };
  };
}
