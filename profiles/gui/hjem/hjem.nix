{
  inputs,
  pkgs,
  richenLib,
  ...
}:
let
  equibopTheme = import ./config/equibop/_theme.nix { inherit (richenLib) theme; };
  qtTheme = import ./config/qt/_theme.nix { inherit (richenLib) theme; };
  spicetifyManaged = import ./config/spicetify/_managed.nix {
    inherit pkgs;
    inherit (richenLib) theme;
  };
  equibopCss = pkgs.replaceVars ./config/equibop/system24-grove.css equibopTheme.replacements;
  kvantumConfig = pkgs.replaceVars ./config/Kvantum/wallbash/wallbash.kvconfig qtTheme.kvantumConfigReplacements;
  kvantumSvg = pkgs.replaceVars ./config/Kvantum/wallbash/wallbash.svg qtTheme.kvantumSvgReplacements;
  kdeglobals = pkgs.writeText "kdeglobals-${richenLib.theme.name}" qtTheme.kdeglobals;
in
{
  imports = [
    inputs.hjem.nixosModules.default
  ];

  systemd.services.greetd = {
    wants = [ "hjem-update-state@${richenLib.vars.username}.service" ];
    after = [ "hjem-update-state@${richenLib.vars.username}.service" ];
  };

  hjem = {
    users.${richenLib.vars.username} = {
      user = richenLib.vars.username;
      directory = "/home/${richenLib.vars.username}";
      clobberFiles = true;
      files = {
        ".config/Kvantum/kvantum.kvconfig" = {
          type = "copy";
          permissions = "0644";
          source = ./config/Kvantum/kvantum.kvconfig;
        };
        ".config/Kvantum/wallbash/wallbash.kvconfig" = {
          type = "copy";
          permissions = "0644";
          source = kvantumConfig;
        };
        ".config/Kvantum/wallbash/wallbash.svg" = {
          type = "copy";
          permissions = "0644";
          source = kvantumSvg;
        };
        ".local/share/flatpak/overrides/global".text = ''
          [Context]
          filesystems=xdg-config/Kvantum:ro;

          [Environment]
          QT_QPA_PLATFORMTHEME=kde
          QT_STYLE_OVERRIDE=kvantum
        '';
        ".config/kdeglobals".source = kdeglobals;
        ".config/qt6ct".source = ./config/qt6ct;
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
