{
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
  ];

  # Install mangowc and minimal desktop dependencies
  environment.systemPackages = with pkgs; [
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
    fzf
    (wrap "mango")
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
    home = "/home/mango";
    createHome = true;
    shell = "${(wrap "zsh")}/bin/zsh";
  };

    boot.plymouth = {
    enable = true;
    theme = "spinner";
  };

  users.defaultUserShell = "${(wrap "zsh")}/bin/zsh";

  environment.etc."mango/wall.png".source = ./swaybg/wall.png;

  services.dbus.enable = true;

  fonts = {
    fontDir.enable = true;
    enableDefaultPackages = true;
    packages = with pkgs; [
      gohufont
      nerd-fonts.gohufont
      nerd-fonts.fira-code
      nerd-fonts.noto
      terminus_font
    ];
    fontconfig = {
      enable = true;
      antialias = true;
      hinting = {
        enable = true;
        style = "slight";
      };
      subpixel = {
        rgba = "rgb";
      };
      defaultFonts = {
        monospace = [ "GohuFont Nerd Font" "FiraCode Nerd Font" "Noto Sans Mono" ];
      };
    };
  };
  services.getty.autologinUser = "mango";

  console = {
    font = "Terminus32x16";
    keyMap = "us";
    packages = with pkgs; [
      terminus_font
    ];
  };
}
