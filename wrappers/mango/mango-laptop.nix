{
  inputs,
  pkgs,
  richenLib,
  stdenv,
  ...
}:
let
  mangoBase = pkgs.callPackage ./_base-config.nix { inherit inputs pkgs richenLib; };
  oakDisplayLayout = pkgs.writeShellScriptBin "oak-display-layout" ''
    mode="''${1:-dock}"
    outputs="$(${pkgs.wlr-randr}/bin/wlr-randr --json)"

    output_for_model() {
      printf '%s\n' "$outputs" | ${pkgs.jq}/bin/jq -r --arg model "$1" 'first(.[] | select(.model == $model) | .name) // empty'
    }

    benq="$(output_for_model "BenQ GW2780")"
    center="$(output_for_model "Dell S2716DG")"
    side="$(output_for_model "DELL E2020H")"
    edp="$(printf '%s\n' "$outputs" | ${pkgs.jq}/bin/jq -r 'first(.[] | select(.name == "eDP-1") | .name) // empty')"

    if [ "$mode" = "laptop" ]; then
      if [ -n "$edp" ]; then
        ${pkgs.wlr-randr}/bin/wlr-randr --output "$edp" --on --preferred --pos 0,0 --transform normal --scale 1.5
      fi
      exit 0
    fi

    if [ -n "$benq" ] && [ -n "$center" ] && [ -n "$side" ]; then
      args=(
        --output "$benq" --on --mode 1920x1080@60.000000Hz --pos 0,0 --transform 90 --scale 1
        --output "$center" --on --mode 2560x1440@119.998001Hz --pos 1080,0 --transform normal --scale 1 --adaptive-sync disabled
        --output "$side" --on --mode 1600x900@60.000000Hz --pos 3640,0 --transform 270 --scale 1
      )

      if [ -n "$edp" ]; then
        args+=(--output "$edp" --off)
      fi

      ${pkgs.wlr-randr}/bin/wlr-randr "''${args[@]}"
    fi
  '';
  config = ''
    exec-once=${oakDisplayLayout}/bin/oak-display-layout dock

    # ============================================
    # TAG RULES - Layout hints per monitor
    # ============================================
    # Tag 1 - Main
    tagrule=id:1,monitor_model:BenQ GW2780,layout_name:scroller
    tagrule=id:1,monitor_model:Dell S2716DG,layout_name:scroller
    tagrule=id:1,monitor_model:DELL E2020H,layout_name:scroller

    # Tag 2-9 - Projects (same layout as Tag 1)
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

    # ============================================
    # MONITOR RULES
    # ============================================
    monitorrule=model:BenQ GW2780,width:1920,height:1080,refresh:60,x:0,y:0,rr:1
    monitorrule=model:Dell S2716DG,width:2560,height:1440,refresh:120,x:1080,y:0,rr:0
    monitorrule=model:DELL E2020H,width:1600,height:900,refresh:60,x:3640,y:0,scale:1,rr:3
    monitorrule=name:eDP-1,width:3200,height:2000,refresh:60,x:5240,y:0,scale:1.5,vrr:0,rr:0

    # ============================================
    # WINDOW RULES
    # ============================================
    windowrule=tags:1,appid:equibop,monitor:model:DELL E2020H
    windowrule=tags:1,appid:steam_app_.*,monitor:model:Dell S2716DG

    # ============================================
    # DISPLAY LAYOUT BINDINGS
    # ============================================
    bind=SUPER+SHIFT,D,spawn,${oakDisplayLayout}/bin/oak-display-layout dock
    bind=SUPER+SHIFT,L,spawn,${oakDisplayLayout}/bin/oak-display-layout laptop

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

    # ============================================
    # SECRET TAG (main monitor only - not synced)
    # ============================================
    # Toggle tag 9 on main monitor only (Hyprland-style secret workspace)
    bind=SUPER,S,view,9,monitor:model:Dell S2716DG
    bind=SUPER+ALT,S,tagcrossmon,9,monitor:model:Dell S2716DG

    cursor_size=48
  '';
  fullConfig = config + "\n" + mangoBase;
in
inputs.wrappers.lib.wrapPackage {
  inherit pkgs;
  package = inputs.mango.packages.${pkgs.system}.mango;
  flags."-c" = "/home/richen/.config/mango/config.conf";
  filesToPatch = [
    "share/wayland-sessions/mango.desktop"
  ];
  passthru.config.content = fullConfig;
}
