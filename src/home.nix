{ pkgs, ... }:
{

  imports = [
    ./modules/hm/dev.nix
    #./modules/hm/expo-dev.nix
    ./modules/hm/obs.nix
    ./modules/hm/zsh.nix
    ./modules/hm/easyeffects.nix
    ./modules/hm/games.nix
    ./modules/hm/git.nix
    ./modules/hm/obsidian.nix
  ];

  home.packages = with pkgs; [
    comma
    vesktop
  ];

  modules = {
    easyeffects.enable = true;
    git.enable = true;
    obsidian.enable = true;
  };

  home.file = {
    ".config/hypr/userprefs.conf" = pkgs.lib.mkForce {
      source = ./misc/userprefs.conf;
      force = true;
      mutable = true;
    };
    ".config/kitty/kitty.conf" = {
      source = ./misc/kitty.conf;
      force = true;
      mutable = true;
    };
    ".config/waybar/config.ctl" = {
      source = ./misc/config.ctl;
      force = true;
      mutable = true;
    };

  };
}
