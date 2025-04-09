{ inputs, ... }:
{
  imports = [
    inputs.richendots-private.nixosModules.fern
    ../../common
    ./drivers.nix
    ./sunshine.nix
    ./vfio
    ./wol.nix
    ./openrgb.nix
  ];

  modules = {
    autologin.enable = false;
    boot.enable = true;
    steam.enable = true;
    # fern specific modules
    fern = {
      wol = {
        enable = true;
        interface = "enp7s0";
      };
      drivers.enable = true;
      sunshine.enable = true;
      vfio.enable = true;
      openrgb.enable = true;
    };
  };
}
