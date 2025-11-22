{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
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
    # Add more as needed
  ];

  users.users.mangowc = {
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

  programs.zsh.enable = true;

  xdg.portal = {
    enable = lib.mkDefault true;

    wlr.enable = lib.mkDefault true;

    configPackages = with pkgs; [ mangowc ];
  };

  # Enable polkit agent for authentication dialogs
  services.dbus.enable = true;
  security.polkit.enable = true;
  programs.xwayland.enable = true;

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd mango";
        user = "greeter";
      };
      useTextGreeter = true;
    };
  };
}
