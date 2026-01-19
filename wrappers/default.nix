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
    mango = callPackage ./mango { };
    satty = callPackage ./satty { };
    swaybg = callPackage ./swaybg { };
    swaync = callPackage ./swaync { };
    zsh = callPackage ./zsh { };
    waybar = callPackage ./waybar.nix { };
    vicinae = callPackage ./vicinae { };
    firefox = callPackage ./firefox { };
    keepassxc = callPackage ./keepassxc { };
    git = callPackage ./git.nix { };
    udiskie = callPackage ./udiskie.nix { };
  };
in
wrappers
