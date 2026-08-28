{
  description = "richendots";

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
    glorious-engrammer = {
      url = "github:sunaku/glove80-keymaps";
      flake = false;
    };
    glove80-zmk = {
      url = "git+https://github.com/moergo-sc/zmk.git?ref=refs/pull/36/head";
      flake = false;
    };
    equicord-src = {
      url = "github:Equicord/Equicord/66b106302422b028517dbfe739b26f246acb97dd";
      flake = false;
    };
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
