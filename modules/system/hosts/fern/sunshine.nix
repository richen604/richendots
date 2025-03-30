{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.fern.sunshine;
in
{
  options.modules.fern.sunshine = {
    enable = lib.mkEnableOption "Sunshine streaming server";

    allowedNetworks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "192.168.0.0/16"
        "10.0.0.0/8"
      ];
      description = "Networks allowed to connect to Sunshine";
    };
  };

  config = lib.mkIf cfg.enable {
    # Install sunshine and required X11 packages
    environment.systemPackages = with pkgs; [
      sunshine
    ];

    services.sunshine = {
      enable = true;
      autoStart = true;
      capSysAdmin = true;
      openFirewall = true;
      settings = {
        # key_rightalt_to_key_win = "enabled";
        adapter_name = "/dev/dri/renderD128";
      };
      applications = {
        env = {
          PATH = "$(PATH):$(HOME)/.local/bin";
        };
        apps = [
          {
            name = "Programming Mode (Note 11 2400*1080)";
            prep-cmd = [
              {
                do = "${pkgs.writeShellScript "stream-mode" ''
                  sed -i 's/\$mainMod = Super/\$mainMod = ALT_R/' ~/.config/hypr/keybindings.conf
                  ${pkgs.hyprland}/bin/hyprctl keyword input:kb_layout "us"
                  ${pkgs.hyprland}/bin/hyprctl keyword monitor DP-4,disable
                  ${pkgs.hyprland}/bin/hyprctl keyword monitor DP-6,disable
                  ${pkgs.hyprland}/bin/hyprctl keyword monitor DP-5,addreserved,0,0,0,0
                  ${pkgs.hyprland}/bin/hyprctl keyword monitor DP-5,2320x1080@60,0x0,2
                  ${pkgs.hyprland}/bin/hyprctl keyword misc:cursor_zoom_factor 2
                  ${pkgs.hyprland}/bin/hyprctl keyword misc:no_direct_scanout 1
                ''}";
                undo = "${pkgs.writeShellScript "regular-mode" ''
                  sed -i 's/\$mainMod = ALT_R/\$mainMod = Super/' ~/.config/hypr/keybindings.conf
                  Hyde reload
                  ${pkgs.hyprland}/bin/hyprctl reload
                ''}";
              }
            ];
            auto-detach = "true";
            output = "DP-5";
          }
          {
            name = "Mobile Stream (1080p)";
            prep-cmd = [
              {
                do = "${pkgs.writeShellScript "stream-mode" ''
                  ${pkgs.hyprland}/bin/hyprctl keyword monitor DP-4,disable
                  ${pkgs.hyprland}/bin/hyprctl keyword monitor DP-6,disable
                  sleep 1
                  ${pkgs.hyprland}/bin/hyprctl keyword monitor DP-5,2560x1440@144,0x0,1.6
                  ${pkgs.hyprland}/bin/hyprctl keyword misc:cursor_zoom_factor 1.6
                ''}";
                undo = "${pkgs.writeShellScript "regular-mode" ''

                  ${pkgs.hyprland}/bin/hyprctl reload
                ''}";
              }
            ];
            auto-detach = "true";
            output = "DP-5";
          }
          {
            name = "Mobile Stream (Performance)";
            prep-cmd = [
              {
                do = "${pkgs.writeShellScript "stream-mode" ''
                  ${pkgs.hyprland}/bin/hyprctl keyword monitor DP-4,disable
                  ${pkgs.hyprland}/bin/hyprctl keyword monitor DP-6,disable
                  sleep 1
                  ${pkgs.hyprland}/bin/hyprctl keyword monitor DP-5,1920x1080@144,0x0,1.25
                  ${pkgs.hyprland}/bin/hyprctl keyword misc:cursor_zoom_factor 1.25
                ''}";
                undo = "${pkgs.writeShellScript "regular-mode" ''
                  ${pkgs.hyprland}/bin/hyprctl reload
                ''}";
              }
            ];
            auto-detach = "true";
            output = "DP-5";
          }
        ];
      };
    };

    users.groups.keyd = {
      members = [ "richen" ];
    };
    # Additional groups for Wayland/KMS access
    users.users.richen.extraGroups = [
      "video"
      "input"
      "render"
      "kvm"
      "uinput"
    ];

    # Add uinput configuration
    boot.kernelModules = [ "uinput" ];
    services.udev.extraRules = ''
      KERNEL=="uinput", SUBSYSTEM=="misc", MODE="0660", GROUP="input"
    '';

    # Firewall rules
    networking.firewall = {
      extraCommands = lib.concatMapStrings (net: ''
        iptables -A INPUT -p tcp -s ${net} -j ACCEPT
        iptables -A INPUT -p udp -s ${net} -j ACCEPT
      '') cfg.allowedNetworks;
    };

  };
}
