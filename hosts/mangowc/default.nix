{
  inputs,
  pkgs,
  lib,
  ...
}@args:

let
  myCallPackage = lib.callPackageWith (args);
  wrap = name: myCallPackage (./wrappers + "/${name}.nix") { };
in
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
    grim
    slurp
    firefox
    starship
    (wrap "kitty")
    (wrap "zsh")
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
    shell = (wrap "zsh") + "/bin/zsh";
    initialPassword = "test";
  };

  # shell stuff
  # todo: make wrapped
  users.defaultUserShell = (wrap "zsh") + "/bin/zsh";
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
      # Add powerline fonts for Oh My Zsh themes like Agnoster
      powerline-fonts
    ];
  };

  console = {
    font = "gohufont-uni-14";
    keyMap = "us";
    packages = with pkgs; [
      nerd-fonts.gohufont
    ];
  };
}
