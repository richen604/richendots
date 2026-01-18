{
  inputs,
  ...
}:
{

  imports = [
    ../../common
    ../../desktops
    ./obsidian.nix
  ];

  # todo: move this at some point
  programs.firefoxpwa.enable = true;
  modules = {
    kdeconnect.enable = true;
    common.dev.enable = true;
  };
}
