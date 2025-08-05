{ inputs, ... }:
{
  imports = [
    inputs.richendots-private.nixosModules.oak
    ../../common
    ./powersave
  ];

  modules = {
    # TODO: should be able to enable after install
    boot.enable = true;
    steam.enable = true;
    oak.powersave.enable = true;
  };
}
