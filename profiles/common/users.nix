{ pkgs, richenLib, ... }:
{
  users.users.richen = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "video"
      "input"
      "networkmanager"
    ];
    home = "/home/richen";
    initialPassword = "test";
    createHome = true;
    shell = "${pkgs.lib.getExe richenLib.wrappers.zsh}";
  };
  users.defaultUserShell = "${pkgs.lib.getExe richenLib.wrappers.zsh}";
  environment.shells = [ "${pkgs.lib.getExe richenLib.wrappers.zsh}" ];
}
