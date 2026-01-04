{
  pkgs,
  lib,
  richenLib,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot = {
    plymouth = {
    enable = true;
    theme = "rings";
    themePackages = with pkgs; [
      # By default we would install all themes
      (adi1090x-plymouth-themes.override {
        selected_themes = [ "rings" ];
      })
    ];
    };
    # Enable "Silent boot"
    consoleLogLevel = 3;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "udev.log_priority=3"
      "rd.systemd.show_status=auto"
    ];
  };

  # Global environment variables
  environment.variables = {
    XDG_CURRENT_DESKTOP = "mango";
    XDG_SESSION_TYPE = "wayland";
    NIXOS_OZONE_WL = "1";
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "24";
  };


  # PACKAGES --------------------------------------------------------- 
  # Install mangowc and minimal desktop dependencies
  environment.systemPackages = with pkgs; [
    waybar
    wl-clipboard
    cliphist
    wlsunset
    polkit_gnome

    rofi
    grim
    slurp
    firefox
    fzf
    richenLib.wrappers.mango
    richenLib.wrappers.kitty
    richenLib.wrappers.zsh
    richenLib.wrappers.swaybg
    # cursor
    bibata-cursors
  ];

  # USERS -------------------------------------------------------------
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
    shell = "${pkgs.lib.getExe richenLib.wrappers.zsh}";
  };
  users.defaultUserShell = "${pkgs.lib.getExe richenLib.wrappers.zsh}";

 # FONTS --------------------------------------------------------------
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

  # GRAPHICS / DISPLAY MANAGER ----------------------------------------
  # Lightweight display manager configuration
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd ${pkgs.lib.getExe richenLib.wrappers.mango}";
        user = "greeter";
      };
      initial_session = {
        command = "${pkgs.lib.getExe richenLib.wrappers.mango}";
        user = "mango";
      };
    };
  };

  # Mango compositor requirements
  security.polkit.enable = lib.mkDefault true;
  programs.xwayland.enable = lib.mkDefault true;
  services.graphical-desktop.enable = lib.mkDefault true;
  services.dbus.enable = true;

  # XDG Portal configuration
  xdg.portal = {
    enable = lib.mkDefault true;
    config = {
      mango = {
        default = [
          "gtk"
        ];
        # except those
        "org.freedesktop.impl.portal.Secret" = ["gnome-keyring"];
        "org.freedesktop.impl.portal.ScreenCast" = ["wlr"];
        "org.freedesktop.impl.portal.ScreenShot" = ["wlr"];
        # wlr does not have this interface
        "org.freedesktop.impl.portal.Inhibit" = [];
      };
    };
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
      xdg-desktop-portal-gtk
    ];
    wlr.enable = lib.mkDefault true;
    configPackages = [ richenLib.wrappers.mango ];
  };

  console = {
    # FIXME: good terminal font?
    # font = "Terminus32x16";
    keyMap = "us";
    packages = with pkgs; [
      terminus_font
    ];
  };
}
