{
  inputs,
  pkgs,
  richenLib,
  ...
}:
let
  mangoBase = pkgs.callPackage ./_base-config.nix { };
  mangoModule = pkgs.callPackage ./module.nix { inherit inputs; };
  config = ''
    # Tag rules - vertical layouts for portrait monitors (DP-6, DP-5)
    tagrule=id:1,monitor_name:DP-6,layout_name:vertical_tile
    tagrule=id:2,monitor_name:DP-4,layout_name:tile
    tagrule=id:3,monitor_name:DP-5,layout_name:vertical_tile
    tagrule=id:4,monitor_name:DP-6,layout_name:vertical_tile
    tagrule=id:5,monitor_name:DP-4,layout_name:tile
    tagrule=id:6,monitor_name:DP-5,layout_name:tile
    tagrule=id:7,monitor_name:DP-6,layout_name:vertical_tile
    tagrule=id:8,monitor_name:DP-4,layout_name:tile
    tagrule=id:9,monitor_name:DP-4,layout_name:scroller

    # Pseudo hyprland like secret tag
    bind=SUPER,S,view,9,DP-4
    bind=SUPER+ALT,S,tagcrossmon,9,DP-4

    # Tag view (workspaces)
    bind=SUPER,1,viewcrossmon,1,DP-6
    bind=SUPER,2,viewcrossmon,2,DP-4
    bind=SUPER,3,viewcrossmon,3,DP-5
    bind=SUPER,4,viewcrossmon,4,DP-6
    bind=SUPER,5,viewcrossmon,5,DP-4
    bind=SUPER,6,viewcrossmon,6,DP-5
    bind=SUPER,7,viewcrossmon,7,DP-6
    bind=SUPER,8,viewcrossmon,8,DP-4
    bind=SUPER,9,viewcrossmon,9,DP-4

    # Move client to tag on specific monitor
    bind=SUPER+Alt,1,tagcrossmon,1,DP-6
    bind=SUPER+Alt,2,tagcrossmon,2,DP-4
    bind=SUPER+Alt,3,tagcrossmon,3,DP-5
    bind=SUPER+Alt,4,tagcrossmon,4,DP-6
    bind=SUPER+Alt,5,tagcrossmon,5,DP-4
    bind=SUPER+Alt,6,tagcrossmon,6,DP-5
    bind=SUPER+Alt,7,tagcrossmon,7,DP-6
    bind=SUPER+Alt,8,tagcrossmon,8,DP-4
    bind=SUPER+Alt,9,tagcrossmon,9,DP-4

    # Monitor rules
    monitorrule=name:DP-6,width:1920,height:1080,refresh:60,x:0,y:0,rr:1
    monitorrule=name:DP-4,width:2560,height:1440,refresh:144,x:1080,y:0,rr:0,vrr:1
    monitorrule=name:DP-5,width:1600,height:900,refresh:60,x:3640,y:0,rr:3

    # Window rules
    windowrule=tags:3,isopensilent:1,monitor:DP-5,appid:vesktop

    cursor_size=24
  '';

  fullConfig = mangoBase + "\n" + config;
in
(mangoModule.apply {
  pkgs = pkgs // {
    mangowc = pkgs.callPackage ./_package.nix { inherit inputs; };
  };
  configFile = "/home/richen/.config/mango/config.conf";
  "config.conf".content = fullConfig;
  passthru.config = fullConfig;
}).wrapper
