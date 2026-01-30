{
  inputs,
  pkgs,
  richenLib,
  stdenv,
  ...
}:
let
  mangoBase = pkgs.callPackage ./_base-config.nix { inherit inputs pkgs richenLib; };
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

    monitorrule=name:eDP-1,width:3200,height:2000,refresh:120,x:0,y:0,scale:1.5,vrr:0,rr:0
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
  pkgs = pkgs // {
    mangowc = pkgs.callPackage ./_package.nix { };
  };
  configFile = "/home/richen/.config/mango/config.conf";
  "config.conf".content = fullConfig;
  passthru.config = fullConfig;
}).wrapper
