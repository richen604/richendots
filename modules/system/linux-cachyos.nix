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
  imports = [ inputs.chaotic.nixosModules.default ];
  options.modules.linux-cachyos = {
    enable = lib.mkEnableOption "linux-cachyos";
  };

  config = lib.mkIf cfg.enable {

    boot.kernelPackages = lib.mkForce pkgs.linuxPackages_cachyos;
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
