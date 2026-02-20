{
  inputs,
  pkgs,
  ...
}:
let
  # todo: swaync nextrelease options when available
  sattyWrapper = pkgs.callPackage ./module.nix { inherit inputs; };
in
(sattyWrapper.apply {
  pkgs = pkgs;
  settings = {
    general = {
      # Start Satty in fullscreen mode
      fullscreen = false;
      # # Exit directly after copy/save action. NEXTRELEASE: Does not apply to save as
      # early-exit = true;
      # # Exit directly after save as (NEXTRELEASE)
      # early-exit-save-as = true;
      # Draw corners of rectangles round if the value is greater than 0 (0 disables rounded corners)
      corner-roundness = 0;
      # Select the tool on startup [possible values: pointer, crop, line, arrow, rectangle, text, marker, blur, brush]
      initial-tool = "brush";
      # Configure the command to be called on copy, for example `wl-copy`
      copy-command = "wl-copy";
      # Increase or decrease the size of the annotations
      annotation-size-factor = 2;
      # Filename to use for saving action. Omit to disable saving to file. Might contain format specifiers: https://docs.rs/chrono/latest/chrono/format/strftime/index.html
      # starting with 0.20.0, can contain leading tilde (~) for home directory
      output-filename = "~/Pictures/Screenshots/test-%Y-%m-%d_%H:%M:%S.png";
      # After copying the screenshot, save it to a file as well
      save-after-copy = true;
      # Hide toolbars by default
      default-hide-toolbars = true;
      # Experimental (since 0.20.0): whether window focus shows/hides toolbars. This does not affect initial state of toolbars, see default-hide-toolbars.
      focus-toggles-toolbars = true;
      # Fill shapes by default (since 0.20.0)
      default-fill-shapes = true;
      # The primary highlighter to use, the other is accessible by holding CTRL at the start of a highlight [possible values: block, freehand]
      primary-highlighter = "block";
      # Disable notifications
      disable-notifications = true;
      # Actions to trigger on right click (order is important)
      # [possible values: save-to-clipboard, save-to-file, exit]
      actions-on-right-click = [ ];
      # Actions to trigger on Enter key (order is important)
      # [possible values: save-to-clipboard, save-to-file, exit]
      actions-on-enter = [
        "save-to-clipboard"
        "save-to-file"
        "exit"
      ];
      # Actions to trigger on Escape key (order is important)
      # [possible values: save-to-clipboard, save-to-file, exit]
      actions-on-escape = [
        "save-to-clipboard"
        "exit"
      ];
      # request no window decoration. Please note that the compositor has the final say in this. At this point. requires xdg-decoration-unstable-v1.
      no-window-decoration = true;
      # experimental feature: adjust history size for brush input smoothing (0: disabled, default: 0, try e.g. 5 or 10)
      brush-smooth-history-size = 10;
      # # experimental feature (NEXTRELEASE): The pan step size to use when panning with arrow keys.
      # pan-step-size = 50.0;
      # # experimental feature (NEXTRELEASE): The zoom factor to use for the image.
      # # 1.0 means no zooming.
      # zoom-factor = 1.0;
      # # experimental feature (NEXTRELEASE): The length to move the text when using arrow keys. defaults to 50.0
      # text-move-length = 50.0;
    };
    # Tool selection keyboard shortcuts (since 0.20.0)
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
    # Font to use for text annotations
    font = {
      family = "GohuFont uni14 Nerd Font Propo";
      # # specify fallback fonts (NEXTRELEASE)
      # # Please note, there is no default setting for these and the fonts listed below
      # # are not shipped with Satty but need to be available on the system.
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
    # Custom colours for the colour palette
    color-palette = {
      # These will be shown in the toolbar for quick selection
      palette = [
        "#ff0000" # bright red - high visibility
        "#7AC297" # grove primary accent (light green)
        "#0080ff" # bright blue - info
        "#ffff00" # yellow - warnings
        "#ff8000" # orange - attention
        "#9AE6D9" # grove secondary accent (cyan)
        "#ffffff" # white - light backgrounds
        "#000000" # black - dark backgrounds
      ];
      # These will be available in the color picker as presets
      # Leave empty to use GTK's default
      custom = [
        # high visibility colors
        "#ff0000" # bright red
        "#00ff00" # bright green
        "#0080ff" # bright blue
        "#ffff00" # yellow
        "#ff00ff" # magenta
        "#ff8000" # orange
        "#00ffff" # cyan
        # grove theme - primary greens
        "#295239" # acc-p1
        "#4B7D5F" # acc-p3
        "#65A37E" # acc-p5
        "#7AC297" # acc-p6
        "#9AE6B8" # acc-p7
        "#CCFFE0" # acc-p9
        # grove theme - secondary/tertiary cyans
        "#3A6B63" # acc-s2
        "#65A399" # acc-s5
        "#7AC2B6" # acc-s6
        "#9AE6D9" # acc-s7
        "#AAF0E4" # acc-s8
        # neutrals
        "#ffffff" # white
        "#cccccc" # light gray
        "#888888" # gray
        "#444444" # dark gray
        "#0E1310" # grove bg-p (dark)
        "#000000" # black
      ];
    };
  };
}).wrapper
