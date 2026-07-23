{ theme }:
{
  config = {
    foreground = theme.txt.p;
    background = theme.bg.p;
    selection_foreground = theme.bg.p;
    selection_background = theme.txt.p;
    cursor = theme.acc.p."6";
    cursor_text_color = theme.bg.p;
    active_tab_foreground = theme.acc.p."6";
    active_tab_background = theme.bg.s;
    inactive_tab_foreground = theme.aliases.muted;
    inactive_tab_background = theme.bg.p;
    color0 = theme.acc.p."2";
    color8 = theme.acc.p."4";
    color1 = theme.ui.error;
    color9 = theme.ui.error;
    color2 = theme.acc.p."6";
    color10 = theme.acc.p."7";
    color3 = theme.ui.warning;
    color11 = theme.acc.s."7";
    color4 = theme.syntax.type;
    color12 = theme.syntax.type;
    color5 = theme.syntax.function;
    color13 = theme.syntax.constant;
    color6 = theme.syntax.string;
    color14 = theme.syntax.keyword;
    color7 = theme.syntax.foreground;
    color15 = theme.txt.p;
  };
}
