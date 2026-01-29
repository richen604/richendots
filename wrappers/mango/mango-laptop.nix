{
  inputs,
  pkgs,
  richenLib,
  ...
}:
let
  mangoBase = ./_base-config.nix;
  mangoModule = pkgs.callPackage ./module.nix { inherit inputs richenLib; };
  config = ''
    exec-once=kitty
  '';
  fullConfig = mangoBase + "\n" + config;
in
(mangoModule.apply {
  extraPackages = [
    richenLib.wrappers.zsh
    richenLib.wrappers.swaybg
    richenLib.wrappers.waybar
    richenLib.wrappers.swaync
    richenLib.wrappers.vicinae
    richenLib.wrappers.udiskie
    richenLib.wrappers.keepassxc
    richenLib.wrappers.satty
    richenLib.wrappers.firefox
    richenLib.wrappers.swaylock
    richenLib.wrappers.swayidle
  ];
  pkgs = pkgs;
  configFile = toString "/etc/mango/config.conf";
  "config.conf".content = fullConfig;
  passthru.config = fullConfig;
}).wrapper
