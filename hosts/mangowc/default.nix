{
  inputs,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    inputs.mango.nixosModules.mango
  ];

  # Install mangowc and minimal desktop dependencies
  environment.systemPackages = with pkgs; [
    mangowc
    waybar
    swaybg
    wl-clipboard
    cliphist
    wlsunset
    polkit_gnome

    rofi
    kitty
    grim
    slurp
    firefox
    zsh
    starship
  ];

  users.users.mango = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "video"
      "input"
      "networkmanager"
    ];
    home = "/home/mangowc";
    createHome = true;
    shell = pkgs.zsh;
    initialPassword = "test";
  };

  # shell stuff
  # todo: make wrapped
  users.defaultUserShell = pkgs.zsh;
  programs.starship.enable = true;
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "ls -l";
    };

    ohMyZsh = {
      enable = true;
      plugins = [
        "git"
      ];
      theme = "starship";
    };

    promptInit = ''
      eval "$(starship init zsh)"
    '';

    histSize = 10000;
    histFile = "$HOME/.zsh_history";
    setOptions = [
      "HIST_IGNORE_ALL_DUPS"
    ];
  };
  system.userActivationScripts.zshrc = "touch .zshrc";

  environment.etc."mango/config.conf".source = ./mango/config.conf;

  environment.etc."mango/wall.png".source = ./swaybg/wall.png;

  programs.mango.enable = true;

  services.dbus.enable = true;

  fonts = {
    fontDir.enable = true;
    enableDefaultPackages = true;
    packages = with pkgs; [
      nerd-fonts.gohufont
      nerd-fonts.fira-code
      nerd-fonts.noto
    ];
  };

  console = {
    font = "gohufont-uni-14";
    keyMap = "us";
    packages = with pkgs; [
      nerd-fonts.gohufont
    ];
  };

  services.greetd = {
    enable = true;
    settings = {
      terminal = {
        vt = 1;
      };
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time";
        user = "greeter";
      };
    };
    useTextGreeter = true;
  };
}
