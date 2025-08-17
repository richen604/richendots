{
  inputs,
  ...
}:
let
  pkgs = import inputs.nixpkgs {
    system = "x86_64-linux";
    config.allowUnfree = true;
    config.allowBroken = true;
    overlays = [
      inputs.hydenix.lib.overlays
      (final: prev: {
        userPkgs = import inputs.nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
          config.allowBroken = true;
        };
      })
      (final: prev: {
        plex = prev.plex.overrideAttrs (oldAttrs: rec {
          version = "1.42.1.10060-4e8b05daf";
          src =
            if prev.stdenv.hostPlatform.system == "aarch64-linux" then
              prev.fetchurl {
                url = "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_arm64.deb?_gl=1*mn8had*_gcl_au*Mzg4Mjc2MTUuMTc1NTQwNTMzMA..*_ga*MTQ0MTMwODk3NS4xNzU1NDA1MzMw*_ga_G6FQWNSENB*czE3NTU0MDUzMjkkbzEkZzEkdDE3NTU0MDU0MTkkajU3JGwwJGgw";
                sha256 = "f0c8b1d3e2a4c5f6b7c8d9e0f1a2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p7q8r9s";
              }
            else
              prev.fetchurl {
                url = "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_amd64.deb";
                sha256 = "3a822dbc6d08a6050a959d099b30dcd96a8cb7266b94d085ecc0a750aa8197f4";
              };
        });
      })
    ];
  };
in
{

  nixpkgs.pkgs = pkgs;

  imports = [
    ./hardware-configuration.nix
    ../../modules/system/hosts/cedar
    ../common/private.nix
    inputs.richendots-private.nixosModules.cedar
  ];

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "/home/richen/dev/richendots";
  };
  # for nh.clean
  nix.gc.automatic = pkgs.lib.mkForce false;

  time.timeZone = "America/Vancouver";
  i18n.defaultLocale = "en_CA.UTF-8";

  users.users.richen = {
    isNormalUser = true;
    initialPassword = "hydenix";
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
    ];
    shell = pkgs.zsh;
  };

  boot.loader = {
    grub = {
      enable = true;
      device = "nodev";
      useOSProber = true;
      efiSupport = true;
    };
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
  };

  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    enableCompletion = true;
    ohMyZsh = {
      enable = true;
      plugins = [
        "git"
        "git-extras"
        "git-flow"
        "git-prompt"
        "nix-shell"
        "zsh-autosuggestions"
      ];
    };
  };

  system.stateVersion = "25.05";
}
