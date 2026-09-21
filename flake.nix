{
  description = "richendots";

  nixConfig = {
    extra-substituters = [ "https://trynix.cachix.org" ];
    extra-trusted-public-keys = [
      "trynix.cachix.org-1:xmOWOHz2g/BlpCVQrTEZjSKWPk3S3Dukn1xiSWLidkY="
    ];
  };

  outputs =
    inputs:
    let
      richenLib = import ./lib { inherit inputs; };
    in
    {
      inherit (richenLib)
        devShell
        checks
        deployChecks
        nixosConfigurations
        packages
        ;

      inherit (richenLib.nixpull)
        deploy
        nixpullProfiles
        ;
    };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    trynix = {
      url = "github:fzakaria/trynix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixarr = {
      # Newer revisions do not yet support Jellyfin 12.1 from nixos-unstable.
      url = "github:rasmus-kirk/nixarr/7cc521933dc6800ae81ecfc91fe36237476e4ffb";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak/20d42f0ee98c9fe9f85e8d1de474f1409ed10d05";
    glide = {
      url = "https://github.com/glide-browser/glide/releases/latest/download/glide.linux-x86_64.tar.xz";
      flake = false;
    };
    glorious-engrammer = {
      url = "github:sunaku/glove80-keymaps";
      flake = false;
    };
    glove80-zmk = {
      url = "git+https://github.com/moergo-sc/zmk.git?ref=refs/pull/36/head";
      flake = false;
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    richendots-private = {
      #url = "git+ssh://git@github.com/richen604/richendots-private.git?ref=main";
      url = "path:/mnt/dev/richendots-private";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.disko.follows = "disko";
      inputs.sops-nix.follows = "sops-nix";
      inputs.nixarr.follows = "nixarr";
      inputs.nix-flatpak.follows = "nix-flatpak";
    };
    mango = {
      url = "github:mangowm/mango/wl-only";
      flake = false;
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
}
