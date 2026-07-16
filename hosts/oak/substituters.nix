{ lib, ... }:
{
  nix.settings = {
    connect-timeout = 2;
    substituters = lib.mkForce [
      "http://cedar.richen.sh:5000?priority=10"
      "https://doom-emacs-unstraightened.cachix.org?priority=20"
      "https://cache.nixos-cuda.org?priority=30"
      "https://cache.nixos.org?priority=40"
    ];
  };
}
