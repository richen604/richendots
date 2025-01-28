{ pkgs, ... }:

{

  environment.sessionVariables = {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "$HOME/.steam/root/compatibilitytools.d";
  };

  programs = {
    gamemode.enable = true;
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
    };
  };

  environment.systemPackages = with pkgs; [
    steam
    mangohud
  ];
}
