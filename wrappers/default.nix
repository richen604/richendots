{ inputs, pkgs, ... }:

let
  # TODO: modules should have their own callPackage context matching inputs.wrappers syntax
  callPackage = pkgs.lib.callPackageWith (
    pkgs
    // {
      inherit inputs;
      richenLib = {
        wrappers = wrappers;
      };
    }
  );

  wrappers = {
    kitty = callPackage ./kitty.nix { };
    mango = callPackage ./mango.nix { };
    satty = callPackage ./satty.nix { };
    swaybg = callPackage ./swaybg.nix { };
    swaync = callPackage ./swaync.nix { };
    zsh = callPackage ./zsh.nix { };
    waybar = callPackage ./waybar.nix { };
    vicinae = callPackage ./vicinae.nix { };
    firefox = callPackage ./firefox.nix { };
  };
in
wrappers
