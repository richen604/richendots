{
  inputs,
  ...
}:
{

  imports = [
    ../../profiles/common.nix
    ../../profiles/common-gui.nix
    ../../profiles/desktop.nix
    ./hardware-configuration.nix
    # inputs.richendots-private.nixosModules.fern or { }
  ];

  system.stateVersion = "26.05";

}
