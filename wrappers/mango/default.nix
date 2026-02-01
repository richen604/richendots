{
  inputs,
  pkgs,
  richenLib,
  stdenv,
  ...
}:
let
  mangoBase = pkgs.callPackage ./_base-config.nix { };
  mangoModule = pkgs.callPackage ./module.nix { inherit inputs; };
  config = ''
    # Tag rules
    # layout support: tile,scroller,grid,deck,monocle,center_tile,vertical_tile,vertical_scroller
    tagrule=id:1,monitor_name:DP-11,layout_name:tile
    tagrule=id:2,monitor_name:DP-9,layout_name:tile
    tagrule=id:3,monitor_name:DP-10,layout_name:tile
    tagrule=id:4,monitor_name:DP-11,layout_name:tile
    tagrule=id:5,monitor_name:DP-9,layout_name:tile
    tagrule=id:6,monitor_name:DP-10,layout_name:tile
    tagrule=id:7,monitor_name:DP-11,layout_name:tile
    tagrule=id:8,monitor_name:DP-10,layout_name:tile
    tagrule=id:9,monitor_name:DP-9,layout_name:scroller

    #left
    monitorrule=name:DP-11,width:1920,height:1080,refresh:60,x:0,y:0,scale:1,vrr:0,rr:1
    #center
    monitorrule=name:DP-9,width:2560,height:1440,refresh:143.998,x:1080,y:480,scale:1,vrr:0,rr:0
    #right
    monitorrule=name:DP-10,width:1600,height:900,refresh:60,x:3640,y:320,scale:1,vrr:0,rr:3

  '';
  fullConfig = config + "\n" + mangoBase;
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
  pkgs = pkgs // {
    mangowc = pkgs.callPackage ./_package.nix { inherit inputs; };
  };
  configFile = "/etc/mango/config.conf";
  "config.conf".content = fullConfig;
  passthru.config = fullConfig;
}).wrapper
