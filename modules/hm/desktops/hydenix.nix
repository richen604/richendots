{
  lib,
  config,
  ...
}:

with lib;

let
  cfg = config.desktops.hydenix;
in
{

  imports = [
    # inputs.nix-index-database.homeModules.nix-index
  ];

  options.desktops.hydenix = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Hydenix desktop configuration";
    };

    hostname = mkOption {
      type = types.str;
      description = "Hostname for Hydenix desktop, used to determine userprefs.conf";
      example = "fern";
    };
  };

  config = mkIf cfg.enable {
    hydenix.hm.firefox.enable = mkForce false;

    # for spotify
    home.sessionVariables = {
      XDG_DATA_DIRS = "$XDG_DATA_DIRS:$HOME/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share";
    };

    home.file.".config/uwsm/env-hyprland.d/hyprland-env.conf".text = ''

      # Host-specific configuration for ${cfg.hostname}
      ${
        if cfg.hostname == "fern" then
          ''
            export = AQ_DRM_DEVICES,/dev/dri/card1
          ''
        else if cfg.hostname == "oak" then
          ''
            export = AQ_DRM_DEVICES,/dev/dri/card0
          ''
        else
          ''''
      }
    '';

    # FIXME: should use `config.hostname` and no assertions should be made
    assertions = [
      {
        assertion = builtins.elem cfg.hostname [
          "fern" # Desktop
          "oak" # Laptop
          "pine" # Media
          "cedar" # Server
          "sapling" # Live USB OS
          "clover" # Main VM
        ];
        message = "Hostname must be one of: fern, oak, pine, cedar, sapling, clover";
      }
    ];

    hydenix.hm = {
      enable = true;
      shell.pokego.enable = true;
      shell.fastfetch.enable = false;
      git = {
        enable = true;
        # FIXME: private module, change info
        name = "richen604";
        email = "56615615+richen604@users.noreply.github.com";
      };
      terminals.kitty.configText = ''
        confirm_os_window_close 0
        font_size 15.0
      '';
      theme = {
        active = "BlueSky";
        themes = [
          "BlueSky"
          "Vanta Black"
          "Cosmic Blue"
          "AbyssGreen"
          "Greenify"
          "Gruvbox Retro"
          "Catppuccin Mocha"
        ];
      };
      spotify.enable = false;

      hyprland = {
        animations.preset = "standard";
        shaders.active = "disable";
        workflows = {
          active = "noborders";
          overrides = {
            "noborders" = ''
              $WORKFLOW_ICON=
              $WORKFLOW_DESCRIPTION = Removes border gaps and shadows for fullscreening applications but keeps existing blur and animations

              decoration {
                rounding = 0
                shadow {
                  enabled = false
                }
              }
              general {
                gaps_in = 0
                gaps_out = 0
                border_size = 1
              }
            '';
          };
        };
        keybindings.extraConfig = ''
          # Alt + Enter to toggle fullscreen
          bind = ALT, Return, fullscreen, 0
          # Alt + Tab to cycle between fullscreen windows
          bind = ALT, Tab, cyclenext
          bind = ALT, Tab, bringactivetotop
        '';
        windowrules.extraConfig = ''
          # common settings
          windowrulev2 = opacity 0.90 0.90,class:^(code-oss)$
          windowrulev2 = opacity 0.90 0.90,class:^(Code)$
          windowrulev2 = opacity 0.90 0.90,class:^(code)$
          windowrulev2 = opacity 0.90 0.90,class:^(code-url-handler)$
          windowrulev2 = opacity 0.90 0.90,class:^(cursor-url-handler)$
          windowrulev2 = opacity 0.90 0.90,class:^(code-insiders-url-handler)$
          windowrulev2 = opacity 1 1,class:^(firefox)$
          # vesktop blur
          windowrulev2 = opacity 0.90 0.90,class:^(vesktop)$
          windowrulev2 = workspace 3,class:^(vesktop)$

          windowrulev2 = float,center,size 600 400,class:^(org.keepassxc.KeePassXC)$
        '';
        nvidia.enable = false;
        extraConfig = ''
          # Host-specific configuration for ${cfg.hostname}
          ${
            if cfg.hostname == "fern" then
              ''
                # left to right
                monitor=desc:BNQ BenQ GW2780 ET85P0086404U,1920x1080,-1080x-130,1,transform,1
                monitor=desc:Dell Inc. Dell S2716DG ##ASMV9wwvvm3d,2560x1440@60,0x0,1
                monitor=desc:Dell Inc. DELL E2020H BJ7NFJ3,1600x900,2560x-130,1,transform,3

                # Workspace Rules using workspace selectors
                workspace=1,monitor:desc:BNQ BenQ GW2780 ET85P0086404U
                workspace=4,monitor:desc:BNQ BenQ GW2780 ET85P0086404U
                workspace=7,monitor:desc:BNQ BenQ GW2780 ET85P0086404U

                workspace=2,monitor:desc:Dell Inc. Dell S2716DG ##ASMV9wwvvm3d
                workspace=5,monitor:desc:Dell Inc. Dell S2716DG ##ASMV9wwvvm3d
                workspace=8,monitor:desc:Dell Inc. Dell S2716DG ##ASMV9wwvvm3d

                workspace=3,monitor:desc:Dell Inc. DELL E2020H BJ7NFJ3
                workspace=6,monitor:desc:Dell Inc. DELL E2020H BJ7NFJ3
                workspace=9,monitor:desc:Dell Inc. DELL E2020H BJ7NFJ3

                # Set initial workspaces
                workspace=1,monitor:desc:BNQ BenQ GW2780 ET85P0086404U,default:true
                workspace=2,monitor:desc:Dell Inc. Dell S2716DG ##ASMV9wwvvm3d,default:true
                workspace=3,monitor:desc:Dell Inc. DELL E2020H BJ7NFJ3,default:true

                # No need to disable hardware cursors on AMD
                # AMD generally has good hardware cursor support
                cursor:no_hardware_cursors = false

                # Disable NVIDIA monitor when it's bound to the host
                monitor=desc:Dell Inc. Dell S2716DG JCVN087U07EQ,disable
              ''
            else if cfg.hostname == "oak" then
              ''
                # Laptop-specific settings
                monitor=,3200x2000@60,0x0,1.6,vrr,1
                env = GDK_SCALE,1.6
                env = QT_SCALE_FACTOR,1.6
              ''
            else
              ''
                # Default settings
                monitor=,preferred,auto,1
              ''
          }
          # Launch vesktop after a delay without blocking boot
          exec-once = vesktop

          exec-once = keepassxc

          exec-once = yubikey-touch-detector --libnotify
        '';
      };
    };
  };
}
