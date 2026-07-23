{ theme }:
{
  name = theme.name;
  theme = {
    meta = {
      version = 1;
      name = theme.name;
      description = "${theme.name} theme generated from richenLib.theme";
      variant = "dark";
      inherits = "vicinae-dark";
    };
    colors = {
      core = {
        background = theme.bg.p;
        foreground = theme.txt.p;
        secondary_background = theme.bg.s;
        border = theme.acc.p."2";
        accent = theme.acc.p."6";
      };
      accents = {
        blue = theme.syntax.type;
        green = theme.acc.p."6";
        magenta = theme.syntax.function;
        orange = theme.ui.warning;
        purple = theme.syntax.constant;
        red = theme.ui.error;
        yellow = theme.acc.s."7";
        cyan = theme.syntax.string;
      };
    };
  };
}
