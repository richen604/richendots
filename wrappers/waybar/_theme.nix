{ theme }:
{
  colors = {
    bar-background = "rgba(0, 0, 0, 0.1)";
    background = theme.bg.p;
    foreground = theme.acc.p."6";
    active-background = theme.bg.s;
    active-foreground = theme.txt.p;
    hover-background = theme.bg.s;
    hover-foreground = theme.acc.p."7";
    urgent = theme.ui.error;
    warning = theme.ui.warning;
  };
}
