{
  inputs,
  pkgs,
  richenLib,
  ...
}:
let
  mangoBase = pkgs.callPackage ./_base-config.nix { inherit richenLib; };
  config = ''
    exec-once=systemctl --user start sunshine.service

    # Tag rules
    # layout support: tile,scroller,grid,deck,monocle,center_tile,vertical_tile,vertical_scroller
    tagrule=id:1,monitor_model:BenQ GW2780,layout_name:scroller
    tagrule=id:1,monitor_model:Dell S2716DG,layout_name:scroller
    tagrule=id:1,monitor_model:DELL E2020H,layout_name:scroller

    tagrule=id:2,monitor_model:BenQ GW2780,layout_name:scroller
    tagrule=id:2,monitor_model:Dell S2716DG,layout_name:scroller
    tagrule=id:2,monitor_model:DELL E2020H,layout_name:scroller

    tagrule=id:3,monitor_model:BenQ GW2780,layout_name:scroller
    tagrule=id:3,monitor_model:Dell S2716DG,layout_name:scroller
    tagrule=id:3,monitor_model:DELL E2020H,layout_name:scroller

    tagrule=id:4,monitor_model:BenQ GW2780,layout_name:scroller
    tagrule=id:4,monitor_model:Dell S2716DG,layout_name:scroller
    tagrule=id:4,monitor_model:DELL E2020H,layout_name:scroller

    tagrule=id:5,monitor_model:BenQ GW2780,layout_name:scroller
    tagrule=id:5,monitor_model:Dell S2716DG,layout_name:scroller
    tagrule=id:5,monitor_model:DELL E2020H,layout_name:scroller

    tagrule=id:6,monitor_model:BenQ GW2780,layout_name:scroller
    tagrule=id:6,monitor_model:Dell S2716DG,layout_name:scroller
    tagrule=id:6,monitor_model:DELL E2020H,layout_name:scroller

    tagrule=id:7,monitor_model:BenQ GW2780,layout_name:scroller
    tagrule=id:7,monitor_model:Dell S2716DG,layout_name:scroller
    tagrule=id:7,monitor_model:DELL E2020H,layout_name:scroller

    tagrule=id:8,monitor_model:BenQ GW2780,layout_name:scroller
    tagrule=id:8,monitor_model:Dell S2716DG,layout_name:scroller
    tagrule=id:8,monitor_model:DELL E2020H,layout_name:scroller

    tagrule=id:9,monitor_model:BenQ GW2780,layout_name:scroller
    tagrule=id:9,monitor_model:Dell S2716DG,layout_name:scroller
    tagrule=id:9,monitor_model:DELL E2020H,layout_name:scroller

    # Monitor rules
    monitorrule=model:BenQ GW2780,width:1920,height:1080,refresh:60,x:0,y:0,rr:1
    monitorrule=model:Dell S2716DG,width:2560,height:1440,refresh:120,x:1080,y:0,rr:0
    monitorrule=model:DELL E2020H,width:1600,height:900,refresh:60,x:3640,y:0,scale:1,rr:3

    # ============================================
    # TAG VIEW BINDINGS (synctag=1 - all monitors show same tag)
    # ============================================
    bind=SUPER,1,view,1,1
    bind=SUPER,2,view,2,1
    bind=SUPER,3,view,3,1
    bind=SUPER,4,view,4,1
    bind=SUPER,5,view,5,1
    bind=SUPER,6,view,6,1
    bind=SUPER,7,view,7,1
    bind=SUPER,8,view,8,1
    bind=SUPER,9,view,9,1

    # ============================================
    # MOVE WINDOW TO TAG (without switching view)
    # ============================================
    bind=SUPER+ALT,1,tagsilent,1
    bind=SUPER+ALT,2,tagsilent,2
    bind=SUPER+ALT,3,tagsilent,3
    bind=SUPER+ALT,4,tagsilent,4
    bind=SUPER+ALT,5,tagsilent,5
    bind=SUPER+ALT,6,tagsilent,6
    bind=SUPER+ALT,7,tagsilent,7
    bind=SUPER+ALT,8,tagsilent,8
    bind=SUPER+ALT,9,tagsilent,9

    # ============================================
    # TOGGLE TAG ON CURRENT WINDOW
    # ============================================
    bind=SUPER+SHIFT,1,view,1
    bind=SUPER+SHIFT,2,view,2
    bind=SUPER+SHIFT,3,view,3
    bind=SUPER+SHIFT,4,view,4
    bind=SUPER+SHIFT,5,view,5
    bind=SUPER+SHIFT,6,view,6
    bind=SUPER+SHIFT,7,view,7
    bind=SUPER+SHIFT,8,view,8
    bind=SUPER+SHIFT,9,view,9

    # Pseudo hyprland like secret tag
    bind=SUPER,S,view,9,
    bind=SUPER+ALT,S,tagsilent,9

    cursor_size=24
  '';

  fullConfig = mangoBase + "\n" + config;
in
inputs.wrappers.lib.wrapPackage {
  inherit pkgs;
  package = inputs.mango.packages.${pkgs.system}.mango;
  flags."-c" = "$HOME/.config/mango/config.conf";
  filesToPatch = [
    "share/wayland-sessions/mango.desktop"
  ];
  passthru.config.content = fullConfig;
}
