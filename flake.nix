{
  description = "template for hydenix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    richendots-private = {
      #url = "git+ssh://git@github.com/richen604/richendots-private.git?ref=main";
      url = "path:/mnt/dev/richendots-private";
      inputs.nixarr.inputs.nixpkgs.follows = "nixpkgs";
      inputs.sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    };
    mango = {
      url = "github:mangowm/mango/wl-only";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    nix-doom-emacs-unstraightened = {
      url = "github:marienz/nix-doom-emacs-unstraightened";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.emacs-overlay.follows = "nixpkgs";
    };
    hjem = {
      url = "github:feel-co/hjem";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, ... }@inputs:
    let
      richenLib = import ./lib { inherit inputs; };
      nixpull =
        let
          lib = inputs.nixpkgs.lib;
          hosts = self.nixosConfigurations;
          hostSystem = host: hosts.${host}.pkgs.stdenv.hostPlatform.system;
          activatable = host: inputs.deploy-rs.lib.${hostSystem host}.activate.nixos hosts.${host};
          deploy = {
            nodes = lib.mapAttrs (host: _configuration: {
              hostname = host;
              profiles.system = {
                user = "root";
                path = activatable host;
              };
            }) hosts;
          };
        in
        {
          nixpullProfiles = lib.mapAttrs (host: _configuration: activatable host) hosts;
          inherit deploy;
          checks = lib.mapAttrs (_system: deployLib: deployLib.deployChecks deploy) inputs.deploy-rs.lib;
        };
    in
    {
      nixosConfigurations = {
        fern = richenLib.mkHost {
          hostname = "fern";
          system = "x86_64-linux";
          profile = "desktop";
          stateVersion = "26.05";
        };
        oak = richenLib.mkHost {
          hostname = "oak";
          system = "x86_64-linux";
          profile = "laptop";
          stateVersion = "26.05";
        };
        cedar = richenLib.mkHost {
          hostname = "cedar";
          system = "x86_64-linux";
          profile = "server";
          stateVersion = "25.05";
        };
      };

      packages = richenLib.forEachSystem (
        system:
        let
          pkgs = richenLib.pkgsFor system;
          _richenLib = richenLib.mkLib pkgs;
          wrappers = _richenLib.wrappers;
        in
        {
          vm-fern = richenLib.mkVm {
            hostname = "fern";
            system = system;
            profile = "desktop";
            stateVersion = "26.05";
          };
          vm-oak = richenLib.mkVm {
            hostname = "oak";
            system = system;
            profile = "laptop";
            stateVersion = "26.05";
          };
          vm-cedar = richenLib.mkVm {
            hostname = "cedar";
            system = system;
            profile = "server";
            stateVersion = "25.05";
          };
        }
        // wrappers
      );

      devShell = richenLib.forEachSystem (
        system:
        let
          pkgs = richenLib.pkgsFor system;
        in
        pkgs.mkShellNoCC {
          allowSubstitutes = false;
          packages = with pkgs; [
            deadnix
            git
            nil
            nixfmt
            statix
          ];
        }
      );
    }
    // nixpull
    // {
      checks = nixpull.checks;
    };
}
