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
    # nixos-hardware.url = "github:NixOS/nixos-hardware/master";
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
        fern = richenLib.mkHost {
          hostname = "fern";
          system = "x86_64-linux";
          profile = "desktop";
        };
        oak = richenLib.mkHost {
          hostname = "oak";
          system = "x86_64-linux";
          profile = "laptop";
        };
        cedar = richenLib.mkHost {
          hostname = "cedar";
          system = "x86_64-linux";
          profile = "server";
        };
        mangowc = richenLib.mkHost {
          hostname = "mangowc";
          system = "x86_64-linux";
          profile = "desktop";
        };
      };

      packages = richenLib.forEachSystem (
        system:
        let
          pkgs = richenLib.pkgsFor system;
          richenLibInstance = richenLib.mkLib pkgs;
        in
        {
          vm-fern = richenLib.mkVm {
            hostname = "fern";
            system = system;
            profile = "desktop";
          };
          vm-oak = richenLib.mkVm {
            hostname = "oak";
            system = system;
            profile = "laptop";
          };
          vm-cedar = richenLib.mkVm {
            hostname = "cedar";
            system = system;
            profile = "server";
          };
          vm-mango = richenLib.mkVm {
            hostname = "mangowc";
            system = system;
            profile = "desktop";
          };

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
