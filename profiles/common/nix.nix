{ pkgs, richenLib, ... }:
{

  # nh replaces nixos-rebuild, so disabling it saves eval.
  system.tools.nixos-rebuild.enable = false;
  # Unused; disabling it also saves eval.
  system.tools.nixos-option.enable = false;

  systemd.enableStrictShellChecks = true;

  programs.nh.clean = {
    enable = true;
    dates = "weekly";
    extraArgs = "--keep 5";
  };

  nix = {
    package = pkgs.nix;
    gc.automatic = false;
    settings = {
      warn-dirty = false;
      allow-import-from-derivation = false;
      timeout = 7200;
      substituters = richenLib.vars.nix.substituters ++ [
        "https://doom-emacs-unstraightened.cachix.org"
      ];
      fallback = true;
      connect-timeout = 2;
      download-attempts = 2;
      stalled-download-timeout = 10;
      http-connections = 64;
      trusted-public-keys = richenLib.vars.nix.trustedPublicKeys ++ [
        "doom-emacs-unstraightened.cachix.org-1:O5oOlRPnmQEvVaFyuMTmthCEooHbrg54WgSLR07tmg4="
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
