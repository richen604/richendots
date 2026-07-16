{ lib, ... }:
{
  nix.settings.substituters = lib.mkForce [
    "http://192.168.1.227:5000?priority=10"
    "https://doom-emacs-unstraightened.cachix.org"
    "https://cache.nixos-cuda.org"
    "https://cache.nixos.org"
  ];
}
