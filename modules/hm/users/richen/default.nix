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
}
