{
  pkgs,
  richenLib,
  ...
}:
let
  # todo: swaync nextrelease options when available
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
    # quick picks for markup: bright basics plus grove accents.
    color-palette = {
      palette = [
        "#ff0000"
        "#7AC297"
        "#0080ff"
        "#ffff00"
        "#ff8000"
        "#9AE6D9"
        "#ffffff"
        "#000000"
      ];
      custom = [
        "#ff0000"
        "#00ff00"
        "#0080ff"
        "#ffff00"
        "#ff00ff"
        "#ff8000"
        "#00ffff"
        "#295239"
        "#4B7D5F"
        "#65A37E"
        "#7AC297"
        "#9AE6B8"
        "#CCFFE0"
        "#3A6B63"
        "#65A399"
        "#7AC2B6"
        "#9AE6D9"
        "#AAF0E4"
        "#ffffff"
        "#cccccc"
        "#888888"
        "#444444"
        "#0E1310"
        "#000000"
      ];
    };
  };
in
richenLib.lib.wrapPackage {
  package = pkgs.satty;
  flags."-c" = config;
  passthru.config.path = config;
}
