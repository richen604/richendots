{ theme }:
{
  replacements = {
    "theme-bg" = theme.bg.p;
    "theme-bg-secondary" = theme.bg.s;
    "theme-border" = theme.acc.p."2";
    "theme-accent" = theme.acc.p."6";
    "theme-accent-alt" = theme.acc.p."4";
    "theme-icon" = theme.acc.p."6";
    "theme-text" = theme.txt.p;
    "theme-text-alt" = theme.aliases.muted;
    "theme-white" = theme.txt.p;
    "theme-container-yellow" = theme.acc.s."7";
    "theme-container-purple" = theme.syntax.constant;
    "theme-container-blue" = theme.syntax.type;
    "theme-container-turquoise" = theme.syntax.string;
    "theme-container-green" = theme.acc.p."6";
    "theme-container-orange" = theme.ui.warning;
    "theme-container-red" = theme.ui.error;
    "theme-container-pink" = theme.syntax.function;
    "theme-font-family" = theme.ui.fontFamily;
    "theme-border-width" = theme.ui.borderWidth;
    "theme-border-radius" = theme.ui.radius;
  };
}
