{
  pkgs,
  richenLib,
  ...
}:
let
  kittyTheme = import ./_theme.nix { theme = richenLib.theme; };
  colorConfig = pkgs.lib.concatStringsSep "\n" (
    pkgs.lib.mapAttrsToList (key: value: "${key} ${value}") kittyTheme.config
  );
  config = pkgs.writeText "kitty.conf" ''
    shell zsh
    # font settings
    font_family GohuFont uni14 Nerd Font
    bold_font auto
    italic_font auto
    bold_italic_font auto
    font_size 16

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

    ${colorConfig}
  '';
in
richenLib.lib.wrapPackage {
  package = pkgs.kitty;
  flags."--config" = config;
  passthru.config.path = config;
}
