{ lib, theme }:
let
  stripHash = color: lib.removePrefix "#" color;
in
{
  colors = {
    color = "${stripHash theme.bg.p}80";
    line-color = stripHash theme.bg.p;
    ring-color = stripHash theme.acc.p."2";
    inside-color = stripHash theme.bg.p;
    key-hl-color = stripHash theme.acc.p."6";
    separator-color = "00000000";
    text-color = stripHash theme.txt.p;
    text-caps-lock-color = "";
    line-ver-color = stripHash theme.acc.p."5";
    ring-ver-color = stripHash theme.acc.p."6";
    inside-ver-color = stripHash theme.bg.p;
    text-ver-color = stripHash theme.txt.p;
    ring-wrong-color = stripHash theme.ui.error;
    text-wrong-color = stripHash theme.ui.error;
    inside-wrong-color = stripHash theme.bg.p;
    inside-clear-color = stripHash theme.bg.p;
    text-clear-color = stripHash theme.txt.p;
    ring-clear-color = stripHash theme.ui.info;
    line-clear-color = stripHash theme.bg.p;
    line-wrong-color = stripHash theme.bg.p;
    bs-hl-color = stripHash theme.ui.error;
  };
}
