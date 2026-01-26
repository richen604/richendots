{
  inputs,
  pkgs,
  ...
}:
(inputs.wrappers.wrapperModules.swaylock.apply {
  pkgs = pkgs;
  package = pkgs.lib.mkForce pkgs.swaylock-effects;
  settings = {
    daemonize = true;
    clock = true;
    # screenshot = true;
    image = toString ./swaybg/wall.png;
    effect-blur = "5x5";
    effect-vignette = "1:1";
    font = "GohuFont 14 Nerd Font Propo";
    font-size = 50;
    indicator = true;
    indicator-radius = 200;
    indicator-thickness = 15;
    color = "0E131080";
    line-color = "0E1310";
    ring-color = "295239";
    inside-color = "0E1310";
    key-hl-color = "65A37E";
    separator-color = "00000000";
    text-color = "FFFFFF";
    text-caps-lock-color = "";
    line-ver-color = "65A37E";
    ring-ver-color = "7AC297";
    inside-ver-color = "0E1310";
    text-ver-color = "FFFFFF";
    ring-wrong-color = "65A399";
    text-wrong-color = "AAF0E4";
    inside-wrong-color = "0E1310";
    inside-clear-color = "0E1310";
    text-clear-color = "FFFFFF";
    ring-clear-color = "9AE6D9";
    line-clear-color = "0E1310";
    line-wrong-color = "0E1310";
    bs-hl-color = "578F86";
    datestr = "%b-%d-%Y";
    timestr = "%H:%M:%S";
    ignore-empty-password = true;
  };
}).wrapper
