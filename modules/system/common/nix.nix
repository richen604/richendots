{ config, lib, ... }:

{
  # Enable nix ld
  programs.nix-ld.enable = true;

  nix = {
    settings = {
      # Add trusted users
      trusted-users = [
        "root"
        "@wheel"
        "richen"
      ];

      # Enable flakes and new nix command
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      # Auto optimize store
      auto-optimise-store = true;

    };

    # Garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };
}
