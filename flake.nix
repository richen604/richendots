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
    {
      ...
    }@inputs:
    let

      pkgsFor =
        system:
        import inputs.nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

      forEachSystem =
        f:
        inputs.nixpkgs.lib.genAttrs [
          "x86_64-linux"
          "aarch64-linux"
        ] (system: f system);

      mkHost =
        hostname: system:
        let
          richenLib = {
            wrappers = pkgs.callPackage ./wrappers { inherit inputs; };
          };
          pkgs =
            if hostname == "fern" then
              (import inputs.hydenix.inputs.nixpkgs {
                config.allowUnfree = true;
                overlays = [ inputs.hydenix.overlays.default ];
                inherit system;
              })
            else
              pkgsFor system;
        in
        inputs.nixpkgs.lib.nixosSystem {
          inherit pkgs system;
          specialArgs = {
            inputs = if hostname == "fern" then (inputs // inputs.richendots-private.inputs) else inputs;
            inherit hostname richenLib;
          };
          modules = [
            ./hosts/${hostname}
          ];
        };

      mkVm =
        hostname: system:
        (import ./hosts/vm.nix {
          inherit inputs hostname;
          nixosConfiguration = mkHost hostname system;
        }).config.system.build.vm;
    in
    {

      nixosConfigurations = {
        fern = mkHost "fern" "x86_64-linux";
        oak = mkHost "oak" "x86_64-linux";
        cedar = mkHost "cedar" "x86_64-linux";
        mangowc = mkHost "mangowc" "x86_64-linux";
      };

      packages = forEachSystem (
        system:
        let
          pkgs = pkgsFor system;
          wrappers = pkgs.callPackage ./wrappers { inherit inputs pkgs; };
        in
        {
          vm-fern = mkVm "fern" system;
          vm-oak = mkVm "oak" system;
          vm-cedar = mkVm "cedar" system;
          vm-mango = mkVm "mangowc" system;

          wrapped = wrappers;
        }
      );
    };
}
