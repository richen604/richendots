{
  lib,
  pkgs,
  inputs,
  config,
  ...
}:

let
  cfg = config.modules.linux-cachyos;
in
{
  options.modules.linux-cachyos = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable linux-cachyos";
    };
  };

  config = lib.mkIf cfg.enable {

    boot.kernelPackages = lib.mkForce pkgs.linuxPackages_cachyos;

    services.scx.enable = true;
    nix.settings = {
      substituters = [
        "https://chaotic-nyx.cachix.org"
      ];
      trusted-public-keys = [
        "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
      ];
    };
  };
}
