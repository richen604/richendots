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
      richenLib = import ./lib.nix { inherit inputs; };
      nixpull = import ./modules/nixpull/flake-module.nix { inherit inputs self; };
      evalBudgetCheck =
        system:
        let
          pkgs = richenLib.pkgsFor system;
          budgets = {
            cedar = 6673;
            fern = 7178;
            oak = 7185;
          };
          checkHost = host: budget: {
            name = "eval-budget-${host}";
            value =
              pkgs.runCommandLocal "eval-budget-${host}"
                {
                  nativeBuildInputs = [ pkgs.nix ];
                  requiredSystemFeatures = [ "recursive-nix" ];
                }
                ''
                  export HOME=$TMPDIR
                  export NIX_CONFIG='experimental-features = nix-command flakes recursive-nix'
                  start=$(date +%s%3N)
                  nix --quiet eval --raw ${self}#nixosConfigurations.${host}.config.system.build.toplevel.drvPath \
                    --override-input nixpkgs ${inputs.nixpkgs} \
                    --override-input deploy-rs ${inputs.deploy-rs} \
                    --override-input richendots-private ${inputs.richendots-private} \
                    --override-input mango ${inputs.mango} \
                    --override-input nix-doom-emacs-unstraightened ${inputs.nix-doom-emacs-unstraightened} \
                    --override-input hjem ${inputs.hjem} \
                    --read-only \
                    --no-write-lock-file \
                    --option eval-cache false \
                    --option allow-import-from-derivation false \
                    >/dev/null
                  end=$(date +%s%3N)
                  elapsed=$((end - start))

                  if [ "$elapsed" -gt ${toString budget} ]; then
                    printf 'eval budget failed for ${host}: elapsed=%sms budget=%sms over=%sms\n' \
                      "$elapsed" ${toString budget} "$((elapsed - ${toString budget}))" >&2
                    exit 1
                  fi

                  printf 'eval budget ok for ${host}: elapsed=%sms budget=%sms\n' \
                    "$elapsed" ${toString budget}
                  touch "$out"
                '';
          };
        in
        builtins.listToAttrs (inputs.nixpkgs.lib.mapAttrsToList checkHost budgets);
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
      };

      packages = richenLib.forEachSystem (
        system:
        let
          pkgs = richenLib.pkgsFor system;
          _richenLib = richenLib.mkLib pkgs;
          wrappers = _richenLib.wrappers;
        in
        {
          profile-eval = pkgs.callPackage ./packages/profile-eval.nix { };

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
      checks = nixpull.checks // {
        x86_64-linux = nixpull.checks.x86_64-linux // evalBudgetCheck "x86_64-linux";
      };
    };
}
