{
  pkgs,
  lib,
  inputs,
  ...
}:
{

  imports = [
    ./dev.nix
    ./expo-dev.nix
    ./obs.nix
    ./zsh.nix
    ./easyeffects.nix
    ./games.nix
    ./git.nix
    ./obsidian.nix

    inputs.richendots-private.userModules.richen
  ];

  home.packages = with pkgs; [
    comma
    vesktop
  ];

  modules = {
    easyeffects.enable = true;
    git.enable = true;
    obsidian.enable = true;
    obs.enable = true;
  };

  hydenix.hm = {
    enable = true;
    editors.default = "nvim";
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
      source = ../../misc/userprefs.conf;
      force = true;
      mutable = true;
    };
  };
}
