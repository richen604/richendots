{
  inputs,
  pkgs,
  richenLib,
  hostvars,
  ...
}:
let
  vicinae = pkgs.callPackage ./module.nix { inherit inputs; };
  scale = richenLib.scale (hostvars.scale or 1.0);
in
(vicinae.apply {
  pkgs = pkgs;
  settings = {
    close_on_focus_loss = false;
    consider_preedit = true;
    pop_to_root_on_close = true;
    favicon_service = "twenty";
    search_files_in_root = true;
    theme = {
      light = {
        name = "vicinae-light";
        icon_theme = "default";
      };
      dark = {
        name = "forest-green";
        icon_theme = "default";
      };
    };
    font = {
      normal = {
        size = 10;
        normal = "Gohu Font 11 Nerd Font";
      };
    };
  };
  envVar = {
    USE_LAYER_SHELL = "1";
    QT_SCALE_FACTOR = "${toString (scale 1.2)}";
  };
  themes = {
    forest-green = {
      meta = {
        version = 1;
        name = "Forest Green";
        description = "Green-first theme derived from kitty palette";
        variant = "dark";
        # icon = "icons/gruvbox.png";
        inherits = "vicinae-dark";
      };
      colors = {
        core = {
          background = "#0E120F";
          foreground = "#FFFFFF";
          secondary_background = "#142825";
          border = "#295233";
          accent = "#9AE6AD";
        };
        accents = {
          blue = "#9AE6AD";
          green = "#AAF0DC";
          magenta = "#9AE6D0";
          orange = "#FAB387";
          purple = "#CBA6F7";
          red = "#CCFFF9";
          yellow = "#CCFFF7";
          cyan = "#9AE6DA";
        };
      };
    };
  };
}).wrapper
