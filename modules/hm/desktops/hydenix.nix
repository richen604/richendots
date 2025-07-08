{
  inputs,
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
    inputs.hydenix.lib.homeModules
    inputs.nix-index-database.hmModules.nix-index
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
      editors.default = "nvim";
      shell.pokego.enable = true;
      shell.fastfetch.enable = false;
      git = {
        enable = true;
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
    };

    home.file = {
      ".config/hypr/userprefs.conf" = lib.mkForce {
        text = ''
          # Host-specific configuration for ${cfg.hostname}
          ${
            if cfg.hostname == "fern" then
              ''
                # left to right
                monitor=desc:BNQ BenQ GW2780 ET85P0086404U,1920x1080,-1080x-300,1,transform,1
                monitor=desc:Dell Inc. Dell S2716DG ##ASMV9wwvvm3d,2560x1440@60,0x0,1
                monitor=desc:Dell Inc. DELL E2020H BJ7NFJ3,1600x900,2560x0,1,transform,3

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

                env = AQ_DRM_DEVICES,/dev/dri/card1:/dev/dri/card0

                # Enable hardware video acceleration
                env = LIBVA_DRIVER_NAME,radeonsi
                env = VDPAU_DRIVER,radeonsi

                # For hardware video acceleration and better performance
                env = __GLX_VENDOR_LIBRARY_NAME,mesa

                # AMD specific Vulkan settings
                env = AMD_VULKAN_ICD,RADV
                env = RADV_PERFTEST,gpl

                # No need to disable hardware cursors on AMD
                # AMD generally has good hardware cursor support
                cursor:no_hardware_cursors = false
              ''
            else if cfg.hostname == "oak" then
              ''
                # Laptop-specific settings
                monitor=,3200x2000@60,0x0,1.6,vrr,1

                env = AQ_DRM_DEVICES,/dev/dri/card2:/dev/dri/card1
              ''
            else
              ''
                # Default settings
                monitor=,preferred,auto,1
              ''
          }
          # common settings
          windowrulev2 = opacity 0.90 0.90,class:^(code-oss)$
          windowrulev2 = opacity 0.90 0.90,class:^(Code)$
          windowrulev2 = opacity 0.90 0.90,class:^(code-url-handler)$
          windowrulev2 = opacity 0.90 0.90,class:^(cursor-url-handler)$
          windowrulev2 = opacity 0.90 0.90,class:^(code-insiders-url-handler)$
          windowrulev2 = opacity 1 1,class:^(firefox)$
          # vesktop blur
          windowrulev2 = opacity 0.90 0.90,class:^(vesktop)$
          windowrulev2 = workspace 3,class:^(vesktop)$
          # Alt + Enter to toggle fullscreen
          bind = ALT, Return, fullscreen, 0
          # Alt + Tab to cycle between fullscreen windows
          bind = ALT, Tab, cyclenext
          bind = ALT, Tab, bringactivetotop
          # Launch vesktop after a delay without blocking boot
          exec-once = sleep 1 && vesktop

          exec-once = sleep 1 && keepassxc
        '';
        force = true;
        mutable = true;
      };
      ".config/hypr/nvidia.conf" = lib.mkForce {
        enable = false;
      };
    };
  };
}
