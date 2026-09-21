{
  inputs,
  pkgs,
  richenLib,
  ...
}:

pkgs.callPackage ./_mango.nix {
  inherit inputs richenLib;
  cursorSize = 24;
  tagLayouts = {
    "BenQ GW2780" = "vertical_tile";
    "Dell S2716DG" = "vertical_tile";
    "Odyssey G70D" = "scroller";
  };
  env.WLR_DRM_DEVICES = "/dev/dri/nvidia-card:/dev/dri/intel-card";
  config = ''
    # monitor rules
    # The NVIDIA DRM connector reports vrr_capable=0 for this proprietary
    # G-Sync display, so Mango cannot enable Wayland adaptive sync on it.
    monitorrule=model:BenQ GW2780,width:1920,height:1080,refresh:60,x:0,y:0,scale:1,vrr:0,rr:1
    monitorrule=model:Odyssey G70D,width:3840,height:2160,refresh:144,x:1081,y:0,scale:1.25,vrr:0,rr:0
    monitorrule=model:Dell S2716DG,width:2560,height:1440,refresh:60,x:4153,y:295,scale:1.333333,vrr:0,rr:3
    monitorrule=name:^HEADLESS-[0-9]+$,width:1920,height:1080,refresh:60,x:0,y:0,scale:1,vrr:0,rr:0

    # window rules
    windowrule=tags:1,appid:equibop,monitor:model:BenQ GW2780
    windowrule=tags:2,isopensilent:1,appid:Spotify,monitor:model:BenQ GW2780
    windowrule=tags:1,appid:FFPWA-.*,monitor:model:Dell S2716DG
    windowrule=appid:steam,monitor:model:Odyssey G70D
    windowrule=appid:steam_app_.*,monitor:model:Odyssey G70D
    windowrule=tags:1,appid:^Minecraft.*$,monitor:model:Odyssey G70D
    windowrule=appid:^anomalydx11[.]exe$,monitor:model:Odyssey G70D,idleinhibit_when_focus:1

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

    # scratch tag
    bind=SUPER,S,view,9,
    bind=SUPER+ALT,S,tagsilent,9
  '';
}
