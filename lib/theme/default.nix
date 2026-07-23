{ vars }:
rec {
  selectedTheme = vars.theme;

  themes = {
    grove = import ./grove.nix;
    grove-old = import ./grove-old.nix;
  };

  current = themes.${selectedTheme};

  inherit (current)
    name
    bg
    txt
    acc
    aliases
    ui
    syntax
    markup
    diff
    ;
}
