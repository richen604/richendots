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

    # Tag view (workspaces)
    bind=SUPER,1,view,1,0
    bind=SUPER,2,view,2,0
    bind=SUPER,3,view,3,0
    bind=SUPER,4,view,4,0
    bind=SUPER,5,view,5,0
    bind=SUPER,6,view,6,0
    bind=SUPER,7,view,7,0
    bind=SUPER,8,view,8,0
    bind=SUPER,9,view,9,0

    # Pseudo hyprland like secret tag
    bind=SUPER,S,view,9,
    bind=SUPER+ALT,S,tagsilent,9

    # Move client to tag
    bind=SUPER+Alt,1,tag,1,0
    bind=SUPER+Alt,2,tag,2,0
    bind=SUPER+Alt,3,tag,3,0
    bind=SUPER+Alt,4,tag,4,0
    bind=SUPER+Alt,5,tag,5,0
    bind=SUPER+Alt,6,tag,6,0
    bind=SUPER+Alt,7,tag,7,0
    bind=SUPER+Alt,8,tag,8,0
    bind=SUPER+Alt,9,tag,9,0

    monitorrule=name:eDP-1,width:3200,height:2000,refresh:120,x:0,y:0,scale:1.5,vrr:0,rr:0

    cursor_size=48
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
    richenLib.wrappers.swaylock-laptop
    richenLib.wrappers.swayidle-laptop
  ];
  pkgs = pkgs // {
    mangowc = pkgs.callPackage ./_package.nix { inherit inputs; };
  };
  configFile = "/etc/mango/config.conf";
  "config.conf".content = fullConfig;
  passthru.config = fullConfig;
}).wrapper
