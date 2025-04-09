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
    inputs.richendots-private.serviceModules.keepassxc-sync
  ];
}
