{ pkgs, ... }:
{
  nix = {
    package = pkgs.lix;
    gc.automatic = false;
    settings = {
      warn-dirty = false;
      allow-import-from-derivation = false;
      substituters = [
        "http://cedar.richen.sh:5000?priority=10"
        "https://doom-emacs-unstraightened.cachix.org"
        "https://cache.nixos-cuda.org"
        "https://cache.nixos.org"
      ];
      http-connections = 64;
      trusted-public-keys = [
        "richencache:ibHPYDq1KmrAsoHIU+WI6ViUoIoX0SEY45CvBOaPXUY="
        "doom-emacs-unstraightened.cachix.org-1:O5oOlRPnmQEvVaFyuMTmthCEooHbrg54WgSLR07tmg4="
        "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      system-features = [ "recursive-nix" ];
      keep-going = true;
      log-lines = 20;
      keep-derivations = true;
      keep-outputs = true;
      auto-optimise-store = true;
      accept-flake-config = true;
      commit-lockfile-summary = "chore: bump flake.lock";
      allowed-users = [ "@wheel" ];
      trusted-users = [ "@wheel" ];
    };
  };
}
