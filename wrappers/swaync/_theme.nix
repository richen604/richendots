{ theme }:
{
  colors = {
    bg-primary = "alpha(${theme.bg.p}, 0.8)";
    bg-secondary = "alpha(${theme.bg.s}, 0.8)";
    bg-tertiary = theme.bg.s;
    fg-primary = theme.txt.p;
    fg-secondary = theme.acc.p."8";
    fg-muted = theme.aliases.muted;
    accent-primary = theme.acc.p."6";
    accent-secondary = theme.acc.s."6";
    accent-tertiary = theme.acc.p."6";
    border-color = theme.acc.p."2";
    critical-color = theme.ui.error;
    hover-bg = theme.bg.s;
    active-bg = theme.acc.p."2";
  };
}
