{
  pkgs,
  lib,
  hostname,
  inputs,
  richenLib,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
  ];

  boot = {
    loader.grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      useOSProber = true;
    };
  };

  nixpkgs.config.allowUnfree = true;

  time.timeZone = "America/Vancouver";
  i18n.defaultLocale = "en_CA.UTF-8";
  networking.hostName = hostname;
  system.stateVersion = "26.05";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

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

  programs.nix-ld.enable = true;
  programs.dconf.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
  services = {
    dbus.enable = true;
    upower.enable = true;
    openssh.enable = true;
    libinput.enable = true;
  };
  # For trash-cli to work properly
  services.gvfs.enable = true;
  security.polkit.enable = true;
  security.pam.services.swaylock = { };
  security.rtkit.enable = true;

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
    richenLib.wrappers.mango
    richenLib.wrappers.kitty
    richenLib.wrappers.zsh
    richenLib.wrappers.swaybg
    richenLib.wrappers.waybar
    richenLib.wrappers.swaync
    richenLib.wrappers.vicinae
    richenLib.wrappers.satty

    killall # Process termination utility
    wl-clipboard # Wayland clipboard utilities
    wl-clip-persist # Keep Wayland clipboard even after programs close
    cliphist # clipboard manager
    gnumake # Build automation tool
    git # distributed version control system
    fzf # command line fuzzy finder
    polkit_gnome # authentication agent for privilege escalation
    dbus # inter-process communication daemon
    upower # power management/battery status daemon
    mesa # OpenGL implementation and GPU drivers
    dconf # configuration storage system
    dconf-editor # dconf editor
    xdg-utils # Collection of XDG desktop integration tools
    desktop-file-utils # for updating desktop database
    hicolor-icon-theme # Base fallback icon theme
    kdePackages.ark # kde file archiver
    wayland # for wayland support
    egl-wayland # for wayland support
    xwayland # for x11 support
    gobject-introspection # for python packages
    trash-cli # cli to manage trash files
    gawk # awk implementation
    coreutils # coreutils implementation
    bash-completion # Add bash-completion package
    libnotify
    wlsunset
    grim
    slurp
    firefox
    bibata-cursors
    networkmanager
    networkmanagerapplet

    brightnessctl # screen brightness control
    udiskie # manage removable media
    ntfs3g # ntfs support
    exfat # exFAT support
    libinput-gestures # actions touchpad gestures using libinput
    libinput # libinput library
    lm_sensors # system sensors
    pciutils # pci utils
    bluez
    bluez-tools
    blueman
    pipewire
    wireplumber
    pavucontrol
    pamixer
    playerctl
  ];

  # gaming
  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  # audio
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
      };
    };
  };
  services.pipewire.enable = true;
  services.pipewire.alsa.enable = true;
  services.pipewire.alsa.support32Bit = true;
  services.pipewire.pulse.enable = true;
  services.pipewire.wireplumber.enable = true;
  services.blueman.enable = true;

  # networking
  networking.networkmanager.enable = true;
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      # SSH
      22
    ];
    allowedUDPPorts = [
      # DHCP
      68
      546
    ];
  };

  nix.settings.auto-optimise-store = true;

  # vicinae cachix settings
  nix.settings.extra-substituters = [ "https://vicinae.cachix.org" ];
  nix.settings.trusted-public-keys = [
    "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
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
        monospace = [
          "GohuFont Nerd Font"
          "FiraCode Nerd Font"
          "Noto Sans Mono"
        ];
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
  programs.xwayland.enable = lib.mkDefault true;
  services.graphical-desktop.enable = lib.mkDefault true;

  # XDG Portal configuration
  xdg.portal = {
    enable = lib.mkDefault true;
    config = {
      mango = {
        default = [
          "gtk"
        ];
        # except those
        "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
        "org.freedesktop.impl.portal.ScreenShot" = [ "wlr" ];
        # wlr does not have this interface
        "org.freedesktop.impl.portal.Inhibit" = [ ];
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
