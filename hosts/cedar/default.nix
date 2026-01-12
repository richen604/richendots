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
      (final: prev: {
        plex = prev.plex.override {
          plexRaw = prev.plexRaw.overrideAttrs (old: rec {
            pname = "plexmediaserver";
            version = "1.42.1.10060-4e8b05daf";
            src = prev.fetchurl {
              url = "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_amd64.deb";
              sha256 = "sha256:1x4ph6m519y0xj2x153b4svqqsnrvhq9n2cxjl50b9h8dny2v0is";
            };
            passthru = old.passthru // {
              inherit version;
            };
          });
        };
      })
    ];
  };
in
{

  nixpkgs.pkgs = pkgs.lib.mkForce pkgs;

  imports = [
    inputs.home-manager.nixosModules.home-manager
    ./hardware-configuration.nix
    ../../modules/system/hosts/cedar
    ../common/private.nix
    inputs.richendots-private.nixosModules.cedar
  ];

  environment.systemPackages = with pkgs; [
    nixfmt-rfc-style
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
    initialPassword = "richen";
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

  programs.nix-ld.enable = true;

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
      ];
      theme = "robbyrussell";
    };
  };

  system.stateVersion = "25.05";
}
