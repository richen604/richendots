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
    # Tag rules
    # layout support: tile,scroller,grid,deck,monocle,center_tile,vertical_tile,vertical_scroller
    tagrule=id:1,layout_name:scroller
    tagrule=id:2,layout_name:scroller
    tagrule=id:3,layout_name:scroller
    tagrule=id:4,layout_name:scroller
    tagrule=id:5,layout_name:scroller
    tagrule=id:6,layout_name:scroller
    tagrule=id:7,layout_name:scroller
    tagrule=id:8,layout_name:scroller
    tagrule=id:9,layout_name:scroller
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
    richenLib.wrappers.swayidle-laptop
  ];
  pkgs = pkgs;
  configFile = "/etc/mango/config.conf";
  "config.conf".content = fullConfig;
  passthru.config = fullConfig;
}).wrapper
