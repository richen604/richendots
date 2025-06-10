{ inputs, ... }:
{
  imports = [
    # TODO: oak private modules
    # inputs.richendots-private.nixosModules.oak
    ../../common
    ./powersave.nix
  ];

  modules = {
    # TODO: should be able to enable after install
    boot.enable = true;
    steam.enable = true;
    oak.powersave.enable = true;
  };
}
