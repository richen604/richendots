{ inputs, pkgs, ... }:

(inputs.wrappers.wrapperModules.kitty.apply {
  pkgs = pkgs;
  "kitty.conf".content = ''
    shell ${pkgs.lib.getExe (pkgs.callPackage ./zsh.nix {inherit inputs;})}

    # font settings
    font_family GohuFont Nerd Font
    bold_font auto
    italic_font auto
    bold_italic_font auto
    font_size 16.0

    # cursor settings
    cursor_shape block
    cursor_blink_interval 0.5
    cursor_stop_blinking_after 15.0

    # shell integration
    shell_integration enabled

    window_padding_width 4

    # misc
    confirm_os_window_close 0
    cursor_trail 1
    enable_audio_bell no

    foreground              #FFFFFF
    background              #0E120F
    selection_foreground    #0E120F
    selection_background    #FFFFFF
    cursor                  #1E3734 
    cursor_text_color       #FFFFFF

    active_tab_foreground     #0E120F
    active_tab_background     #142825
    inactive_tab_foreground   #142825
    inactive_tab_background   #0E120F

    # black
    color0      #295233
    color8      #578F65

    # red
    color1      #CCFFF9
    color9      #AAF0E7

    # green
    color2      #CCFFF0
    color10     #AAF0DC

    # yellow
    color3      #CCFFF7
    color11     #AAF0E5

    # blue
    color4      #9AE6AD
    color12     #9AE6AD

    # magenta
    color5      #9AE6D0
    color13     #9AE6D0

    # cyan
    color6      #9AE6DA
    color14     #9AE6DA

    # white
    color7      #CCFFF9
    color15     #AAF0E7
  '';
}).wrapper
