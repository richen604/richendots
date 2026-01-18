{
  description = "template for hydenix";

  inputs = {
    nixpkgs.follows = "hydenix/nixpkgs";
    hydenix = {
      url = "github:richen604/hydenix";
      # url = "path:/home/richen/newdev/hydenix";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    richendots-private = {
      # url = "git+ssh://git@github.com/richen604/richendots-private.git?ref=main";
      url = "path:/home/richen/newdev/richendots-private";
    };

    wrappers.url = "github:lassulus/wrappers";
    vicinae.url = "github:vicinaehq/vicinae";
    hjem = {
      url = "github:feel-co/hjem";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { ... }@inputs:
    let
      richenLib = import ./lib.nix { inherit inputs; };
    in
    {
      nixosConfigurations = {
        fern = richenLib.mkHost "fern" "x86_64-linux";
        oak = richenLib.mkHost "oak" "x86_64-linux";
        cedar = richenLib.mkHost "cedar" "x86_64-linux";
        mangowc = richenLib.mkHost "mangowc" "x86_64-linux";
      };

      packages = richenLib.forEachSystem (
        system:
        let
          pkgs = richenLib.pkgsFor system;
          richenLibInstance = richenLib.mkLib pkgs;
        in
        {
          vm-fern = richenLib.mkVm "fern" system;
          vm-oak = richenLib.mkVm "oak" system;
          vm-cedar = richenLib.mkVm "cedar" system;
          vm-mango = richenLib.mkVm "mangowc" system;

          wrapped-kitty = richenLibInstance.wrappers.kitty;
          wrapped-mango = richenLibInstance.wrappers.mango;
          wrapped-satty = richenLibInstance.wrappers.satty;
          wrapped-swaybg = richenLibInstance.wrappers.swaybg;
          wrapped-swaync = richenLibInstance.wrappers.swaync;
          wrapped-zsh = richenLibInstance.wrappers.zsh;
          wrapped-waybar = richenLibInstance.wrappers.waybar;
          wrapped-vicinae = richenLibInstance.wrappers.vicinae;
          wrapped-firefox = richenLibInstance.wrappers.firefox;
          wrapped-keepassxc = richenLibInstance.wrappers.keepassxc;
          wrapped-git = richenLibInstance.wrappers.git;
          wrapped-udiskie = richenLibInstance.wrappers.udiskie;
        }
      );
    };
}
