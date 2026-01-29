{
  pkgs,
  lib,
  inputs,
  hostname,
  richenLib,
  ...
}:
{

  imports = [
    ../../profiles/common.nix
    ../../profiles/common-gui.nix
    ../../profiles/desktop.nix
    ./hardware-configuration.nix
  ];
}
