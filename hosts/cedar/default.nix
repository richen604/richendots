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
  ];

  networking.networkmanager.enable = true;

  networking.interfaces.wlp3s0.wakeOnLan.enable = true;

  services.code-server = {
    enable = true;
    user = "richen";
    group = "users";
    host = "127.0.0.1";
    port = 8080;
    auth = "none";
    package = pkgs.vscode-with-extensions.override {
      vscode = pkgs.code-server;
      vscodeExtensions = with pkgs.vscode-extensions; [
        aaron-bond.better-comments
        alefragnani.project-manager
        bierner.emojisense
        bierner.markdown-mermaid
        bierner.markdown-preview-github-styles
        catppuccin.catppuccin-vsc-icons
        davidanson.vscode-markdownlint
        dbaeumer.vscode-eslint
        donjayamanne.githistory
        eamodio.gitlens
        ecmel.vscode-html-css
        aaron-bond.better-comments
        enkia.tokyo-night
        esbenp.prettier-vscode
        firefox-devtools.vscode-firefox-debug
        geequlim.godot-tools
        github.copilot
        github.vscode-github-actions
        github.vscode-pull-request-github
        golang.go
        ibm.output-colorizer
        jnoortheen.nix-ide
        leonardssh.vscord
        mads-hartmann.bash-ide-vscode
        mkhl.shfmt
        ms-dotnettools.csdevkit
        ms-dotnettools.csharp
        ms-dotnettools.vscode-dotnet-runtime
        ms-python.debugpy
        ms-python.python
        ms-python.vscode-pylance
        ms-vscode.cmake-tools
        ms-vscode.cpptools
        ms-vscode.cpptools-extension-pack
        ms-vscode.makefile-tools
        ms-vscode-remote.remote-ssh
        redhat.vscode-yaml
        saoudrizwan.claude-dev
        streetsidesoftware.code-spell-checker
        tamasfe.even-better-toml
        timonwong.shellcheck
        yoavbls.pretty-ts-errors
        yzhang.markdown-all-in-one
        ziglang.vscode-zig
        ms-vscode-remote.remote-ssh
        ms-vscode-remote.remote-ssh-edit
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    nixfmt-rfc-style
    vim
    neovim
    git
    wpa_supplicant
    kitty
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
