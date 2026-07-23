{ lib, theme }:
let
  stripHash = color: lib.removePrefix "#" color;
in
{
  colorIni = {
    ${theme.name} = {
      accent = stripHash theme.acc.p."6";
      accent-active = stripHash theme.acc.p."7";
      accent-inactive = stripHash theme.bg.s;
      banner = stripHash theme.acc.p."6";
      border-active = stripHash theme.acc.p."6";
      border-inactive = stripHash theme.acc.p."2";
      header = stripHash theme.bg.s;
      highlight = stripHash theme.bg.s;
      main = stripHash theme.bg.p;
      notification = stripHash theme.ui.info;
      notification-error = stripHash theme.ui.error;
      subtext = stripHash theme.aliases.muted;
      text = stripHash theme.txt.p;
    };
  };

  themeName = "tui";
  colorScheme = theme.name;
}
