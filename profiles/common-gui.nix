{
  pkgs,
  inputs,
  richenLib,
  ...
}:
let
  defaultMimeApplications = {
    "inode/directory" = "yazi-kitty.desktop";

    "text/plain" = "nvim.desktop";
    "text/markdown" = "nvim.desktop";
    "text/x-markdown" = "nvim.desktop";
    "text/csv" = "nvim.desktop";
    "text/css" = "nvim.desktop";
    "text/xml" = "nvim.desktop";
    "application/json" = "nvim.desktop";
    "application/javascript" = "nvim.desktop";
    "application/x-shellscript" = "nvim.desktop";

    "application/pdf" = "firefox.desktop";
    "application/xhtml+xml" = "firefox.desktop";
    "application/xml" = "firefox.desktop";
    "text/html" = "firefox.desktop";
    "image/png" = "firefox.desktop";
    "image/jpeg" = "firefox.desktop";
    "image/gif" = "firefox.desktop";
    "image/webp" = "firefox.desktop";
    "image/svg+xml" = "firefox.desktop";
    "video/mp4" = "firefox.desktop";
    "video/webm" = "firefox.desktop";
    "audio/mpeg" = "firefox.desktop";
    "audio/ogg" = "firefox.desktop";
    "audio/wav" = "firefox.desktop";
    "x-scheme-handler/about" = "firefox.desktop";
    "x-scheme-handler/http" = "firefox.desktop";
    "x-scheme-handler/https" = "firefox.desktop";
    "x-scheme-handler/mailto" = "firefox.desktop";

    "application/zip" = "yazi-kitty.desktop";
    "application/x-tar" = "yazi-kitty.desktop";
    "application/gzip" = "yazi-kitty.desktop";
    "application/x-bzip2" = "yazi-kitty.desktop";
    "application/x-7z-compressed" = "yazi-kitty.desktop";
    "application/x-rar-compressed" = "yazi-kitty.desktop";
    "application/zstd" = "yazi-kitty.desktop";
    "application/x-xz" = "yazi-kitty.desktop";
  };

  chromiumX11 = pkgs.symlinkJoin {
    name = "ungoogled-chromium-x11";
    paths = [ pkgs.ungoogled-chromium ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/chromium \
        --unset NIXOS_OZONE_WL \
        --add-flags "--ozone-platform=x11"
    '';
  };

  equibopX11 = pkgs.symlinkJoin {
    name = "equibop-x11";
    paths = [ pkgs.equibop ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/equibop \
        --unset NIXOS_OZONE_WL \
        --set ELECTRON_OZONE_PLATFORM_HINT x11 \
        --add-flags "--ozone-platform=x11"
    '';
  };

  catppuccinGtkPython = pkgs.python313.override {
    packageOverrides = _pyFinal: pyPrev: {
      catppuccin = pyPrev.catppuccin.overridePythonAttrs (_old: {
        doCheck = false;
        pythonImportsCheck = [ ];
      });
    };
  };
in
{

  imports = [
    inputs.hjem.nixosModules.default
  ];

  # packages
  environment.systemPackages = [
    richenLib.wrappers.kitty
    richenLib.wrappers.zsh
    richenLib.wrappers.swaybg
    richenLib.wrappers.swaync
    richenLib.wrappers.vicinae
    richenLib.wrappers.satty
    richenLib.wrappers.firefox
    richenLib.wrappers.keepassxc
    richenLib.wrappers.udiskie

    # cursor, icon, gtk themes
    pkgs.bibata-cursors
    (pkgs.catppuccin-papirus-folders.override {
      accent = "green";
      flavor = "mocha";
    })
    (pkgs.catppuccin-gtk.override {
      accents = [ "green" ];
      python3 = catppuccinGtkPython;
      size = "compact";
      variant = "mocha";
    })
    pkgs.hicolor-icon-theme

    # gtk deps
    pkgs.gtk3
    pkgs.gtk4
    pkgs.glib
    pkgs.nwg-look
    pkgs.adwaita-icon-theme

    # media apps
    pkgs.spicetify-cli

    # social apps
    equibopX11

    # other utils
    pkgs.kdePackages.kdeconnect-kde
    pkgs.wlogout

    # wayland tools
    pkgs.wlr-randr
    pkgs.wl-clipboard
    pkgs.wl-clip-persist
    pkgs.cliphist

    # system services
    pkgs.polkit_gnome
    pkgs.dbus
    pkgs.upower
    pkgs.dconf
    pkgs.dconf-editor

    # desktop integration
    pkgs.xdg-utils
    pkgs.desktop-file-utils

    # notifications/display
    pkgs.libnotify
    pkgs.wlsunset
    pkgs.grim
    pkgs.slurp

    # hardware management
    pkgs.networkmanagerapplet
    pkgs.brightnessctl

    # input
    pkgs.libinput-gestures
    pkgs.libinput

    # bluetooth
    pkgs.bluez
    pkgs.bluez-tools
    pkgs.blueman

    # audio
    pkgs.pipewire
    pkgs.wireplumber
    pkgs.pavucontrol
    pkgs.pamixer
    pkgs.playerctl

    # media/utilities
    pkgs.wf-recorder
    pkgs.dpms-off

    # custom scripts
    (pkgs.callPackage ./scripts/spotify-spicetified.nix { })

    pkgs.obsidian

    pkgs.zed-editor

    pkgs.wayland-pipewire-idle-inhibit

    pkgs.piper
    chromiumX11
    pkgs.prismlauncher
  ];

  services.ratbagd.enable = true;
  programs.dconf.enable = true;
  services.dbus.enable = true;
  services.upower.enable = true;
  services.libinput.enable = true;
  services.gvfs.enable = true;
  security.pam.services.swaylock = { };
  security.rtkit.enable = true;
  hardware.opentabletdriver.enable = true;
  services.xserver.digimend.enable = true;
  # boot
  # todo: limine secure boot
  boot = {
    plymouth = {
      enable = true;
      theme = "liquid";
      themePackages = with pkgs; [
        (adi1090x-plymouth-themes.override {
          selected_themes = [ "liquid" ];
        })
      ];
    };
    # skip grub
    loader.grub.timeoutStyle = "hidden";
    loader.timeout = 0;
    loader.grub.splashImage = null;
    # Enable "Silent boot"
    consoleLogLevel = 3;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "udev.log_priority=3"
      "systemd.show_status=auto"
      "8250.nr_uarts=0"
    ];
  };

  # audio and bluetooth
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

  # theme settings
  programs.dconf.profiles.user.databases = [
    {
      settings = {
        "org/gnome/desktop/interface" = {
          gtk-theme = "catppuccin-mocha-green-compact";
          color-scheme = "prefer-dark";
          font-name = "GohuFont uni14 Nerd Font Propo";
          cursor-theme = "Bibata-Modern-Ice";
          icon-theme = "Papirus-Dark";
          font-antialiasing = "rgba";
          font-hinting = "full";
        };
      };
    }
  ];
  xdg.icons.fallbackCursorThemes = [ "Bibata-Modern-Ice" ];

  # variables
  environment.variables = {
    XDG_CURRENT_DESKTOP = "mango";
    XDG_SESSION_TYPE = "wayland";
    NIXOS_OZONE_WL = "1";
    XCURSOR_THEME = "Bibata-Modern-Ice";
    MOZ_ENABLE_WAYLAND = "1";
    GTK_THEME = "catppuccin-mocha-green-compact";
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    GTK_BACKEND = "wayland;x11";
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
  };

  # default apps
  xdg.mime = {
    defaultApplications = defaultMimeApplications;
    addedAssociations = defaultMimeApplications;
  };

  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true;
  };
  services.flatpak.enable = true;

  programs.steam = {
    enable = true;
  };

  # GRAPHICS / DISPLAY MANAGER ----------------------------------------
  services.greetd.enable = true;

  # mango compositor requirements
  programs.xwayland.enable = true;
  services.graphical-desktop.enable = true;

  xdg.portal = {
    enable = true;
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
    wlr.enable = true;
  };

  hjem = {
    users.richen = {
      user = "richen";
      directory = "/home/richen";
      clobberFiles = true;
      files = {
        ".config/equibop/themes/system24-grove.css".source = ./config/equibop/system24-grove.css;
        ".config/spicetify/config-xpui.ini" = {
          type = "copy";
          permissions = "0644";
          source = ./config/spicetify/config-xpui.ini;
        };
        ".config/spicetify/CustomApps/marketplace/extension.js" = {
          type = "copy";
          permissions = "0644";
          source = ./config/spicetify/CustomApps/marketplace/extension.js;
        };
        ".config/spicetify/CustomApps/marketplace/index.js" = {
          type = "copy";
          permissions = "0644";
          source = ./config/spicetify/CustomApps/marketplace/index.js;
        };
        ".config/spicetify/CustomApps/marketplace/manifest.json" = {
          type = "copy";
          permissions = "0644";
          source = ./config/spicetify/CustomApps/marketplace/manifest.json;
        };
        ".config/spicetify/CustomApps/marketplace/style.css" = {
          type = "copy";
          permissions = "0644";
          source = ./config/spicetify/CustomApps/marketplace/style.css;
        };
        ".config/spicetify/Themes/tui/color.ini" = {
          type = "copy";
          permissions = "0644";
          source = ./config/spicetify/Themes/tui/color.ini;
        };
        ".config/spicetify/Themes/tui/user.css" = {
          type = "copy";
          permissions = "0644";
          source = ./config/spicetify/Themes/tui/user.css;
        };
      };
    };
  };
}
