{ theme }:
{
  replacements = {
    "theme-bg" = theme.bg.p;
    "theme-bg-alt" = theme.bg.s;
    "theme-bg-tertiary" = theme.bg.t;
    "theme-border" = theme.acc.p."2";
    "theme-muted" = theme.aliases.muted;
    "theme-base" = theme.acc.p."5";
    "theme-fg" = theme.txt.p;
    "theme-fg-alt" = theme.syntax.foreground;
    "theme-red" = theme.ui.error;
    "theme-orange" = theme.ui.warning;
    "theme-green" = theme.acc.p."6";
    "theme-teal" = theme.syntax.string;
    "theme-yellow" = theme.ui.warning;
    "theme-blue" = theme.syntax.type;
    "theme-magenta" = theme.syntax.function;
    "theme-violet" = theme.syntax.constant;
    "theme-cyan" = theme.syntax.keyword;
    "theme-dark-cyan" = theme.ui.info;
    "theme-bright-yellow" = theme.acc.s."7";
  };
}
