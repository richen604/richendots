{
  pkgs,
  richenLib,
  ...
}:
let
  sattyTheme = import ./satty/_theme.nix { inherit (richenLib) theme; };
  config = (pkgs.formats.toml { }).generate "satty-config" {
    general = {
      fullscreen = false;
      # early-exit = true;
      # early-exit-save-as = true;
      corner-roundness = 0;
      initial-tool = "brush";
      copy-command = "wl-copy";
      annotation-size-factor = 2;
      output-filename = "~/Pictures/Screenshots/test-%Y-%m-%d_%H:%M:%S.png";
      save-after-copy = true;
      default-hide-toolbars = true;
      focus-toggles-toolbars = true;
      default-fill-shapes = true;
      primary-highlighter = "block";
      disable-notifications = true;
      actions-on-right-click = [ ];
      actions-on-enter = [
        "save-to-clipboard"
        "save-to-file"
        "exit"
      ];
      actions-on-escape = [
        "save-to-clipboard"
        "exit"
      ];
      no-window-decoration = true;
      brush-smooth-history-size = 10;
      # pan-step-size = 50.0;
      # zoom-factor = 1.0;
      # text-move-length = 50.0;
    };
    # single-key satty tool shortcuts
    keybinds = {
      pointer = "p";
      crop = "c";
      brush = "b";
      line = "i";
      arrow = "z";
      rectangle = "r";
      ellipse = "e";
      text = "t";
      marker = "m";
      blur = "u";
      highlight = "g";
    };
    font = {
      family = "GohuFont uni14 Nerd Font Propo";
      # fallback = [
      #   "Noto Sans CJK JP"
      #   "Noto Sans CJK SC"
      #   "Noto Sans CJK TC"
      #   "Noto Sans CJK KR"
      #   "Noto Serif CJK JP"
      #   "Noto Serif JP"
      #   "IPAGothic"
      #   "IPAexGothic"
      #   "Source Han Sans"
      # ];
    };
    # Quick picks for markup from the selected theme.
    color-palette = {
      inherit (sattyTheme) palette custom;
    };
  };
in
richenLib.lib.wrapPackage {
  package = pkgs.satty;
  flags."-c" = config;
  passthru.config.path = config;
}
