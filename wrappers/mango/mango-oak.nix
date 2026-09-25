{
  inputs,
  pkgs,
  richenLib,
  ...
}:

pkgs.callPackage ./_mango.nix {
  inherit inputs richenLib;
  cursorSize = richenLib.hostVars.cursorSize;
  tagLayouts = {
    "BenQ GW2780" = "vertical_tile";
    "DELL E2020H" = "vertical_tile";
    "Dell S2716DG" = "scroller";
  };
  config = ''
    # monitor rules
    monitorrule=model:BenQ GW2780,width:1920,height:1080,refresh:60,x:0,y:0,rr:1
    monitorrule=model:Dell S2716DG,width:2560,height:1440,refresh:120,x:1080,y:0,rr:0
    monitorrule=model:DELL E2020H,width:1600,height:900,refresh:60,x:3640,y:0,scale:1,rr:3
    monitorrule=name:eDP-1,width:3200,height:2000,refresh:60,x:5240,y:0,scale:1.5,vrr:0,rr:0

    # window rules
    windowrule=tags:2,isopensilent:1,monitor:eDP-1,appid:equibop
    windowrule=tags:3,isopensilent:1,monitor:eDP-1,appid:com.spotify.Client
    windowrule=tags:1,appid:steam_app_.*,monitor:model:Dell S2716DG
    windowrule=tags:1,appid:^Minecraft.*$,monitor:model:Dell S2716DG

    # tag view bindings; synctag keeps monitors on the same tag
    bind=SUPER,1,view,1,1
    bind=SUPER,2,view,2,1
    bind=SUPER,3,view,3,1
    bind=SUPER,4,view,4,1
    bind=SUPER,5,view,5,1
    bind=SUPER,6,view,6,1
    bind=SUPER,7,view,7,1
    bind=SUPER,8,view,8,1
    bind=SUPER,9,view,9,1

    # move windows without switching view
    bind=SUPER+ALT,1,tagsilent,1
    bind=SUPER+ALT,2,tagsilent,2
    bind=SUPER+ALT,3,tagsilent,3
    bind=SUPER+ALT,4,tagsilent,4
    bind=SUPER+ALT,5,tagsilent,5
    bind=SUPER+ALT,6,tagsilent,6
    bind=SUPER+ALT,7,tagsilent,7
    bind=SUPER+ALT,8,tagsilent,8
    bind=SUPER+ALT,9,tagsilent,9

    # toggle a tag on the current window
    bind=SUPER+SHIFT,1,view,1
    bind=SUPER+SHIFT,2,view,2
    bind=SUPER+SHIFT,3,view,3
    bind=SUPER+SHIFT,4,view,4
    bind=SUPER+SHIFT,5,view,5
    bind=SUPER+SHIFT,6,view,6
    bind=SUPER+SHIFT,7,view,7
    bind=SUPER+SHIFT,8,view,8
    bind=SUPER+SHIFT,9,view,9

    # scratch tag on the main monitor only
    bind=SUPER,S,view,9,monitor:model:Dell S2716DG
    bind=SUPER+ALT,S,tagcrossmon,9,monitor:model:Dell S2716DG
  '';
}
