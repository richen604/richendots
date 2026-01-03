{ inputs, pkgs, ... }:

(inputs.wrappers.wrapperModules.kitty.apply {
  pkgs = pkgs;
  "kitty.conf".content = ''
    # kitty configuration for mangowc host
    # basic config with font and colors

    # font settings
    font_family FiraCode Nerd Font
    bold_font auto
    italic_font auto
    bold_italic_font auto
    font_size 14.0

    # cursor settings
    cursor_shape block
    cursor_blink_interval 0.5
    cursor_stop_blinking_after 15.0

    # shell integration
    shell_integration enabled

    # misc
    confirm_os_close_window 0
    cursor_trail 1
    enable_audio_bell no
  '';
}).wrapper
