{
  inputs,
  ...
}:
{

  imports = [
    ../../common
    ../../desktops
    ./obsidian.nix
    inputs.richendots-private.userModules.richen
  ];

  # todo: move this at some point
  programs.firefoxpwa.enable = true;
  modules = {
    kdeconnect.enable = true;
  };
}
