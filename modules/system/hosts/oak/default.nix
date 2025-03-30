{ inputs, ... }:
{
  imports = [
    # TODO: oak private modules
    # inputs.richendots-private.nixosModules.oak
    ../../common
  ];

  modules = {
    # TODO: should be able to enable after install
    boot.enable = true;
    steam.enable = true;
    dev.enable = true;
    gamescope.enable = true;
  };
}
