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

    "application/pdf" = "glide.desktop";
    "application/xhtml+xml" = "glide.desktop";
    "application/xml" = "glide.desktop";
    "text/html" = "glide.desktop";
    "image/png" = "glide.desktop";
    "image/jpeg" = "glide.desktop";
    "image/gif" = "glide.desktop";
    "image/webp" = "glide.desktop";
    "image/svg+xml" = "glide.desktop";
    "video/mp4" = "glide.desktop";
    "video/webm" = "glide.desktop";
    "audio/mpeg" = "glide.desktop";
    "audio/ogg" = "glide.desktop";
    "audio/wav" = "glide.desktop";
    "x-scheme-handler/about" = "glide.desktop";
    "x-scheme-handler/http" = "glide.desktop";
    "x-scheme-handler/https" = "glide.desktop";
    "x-scheme-handler/mailto" = "glide.desktop";

    "application/zip" = "yazi-kitty.desktop";
    "application/x-tar" = "yazi-kitty.desktop";
    "application/gzip" = "yazi-kitty.desktop";
    "application/x-bzip2" = "yazi-kitty.desktop";
    "application/x-7z-compressed" = "yazi-kitty.desktop";
    "application/x-rar-compressed" = "yazi-kitty.desktop";
    "application/zstd" = "yazi-kitty.desktop";
    "application/x-xz" = "yazi-kitty.desktop";
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
    richenLib.wrappers.glide
    richenLib.wrappers.keepassxc
    richenLib.wrappers.udiskie
    pkgs.yubikey-manager

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

    # media apps
    pkgs.spicetify-cli

    # social apps
    pkgs.equibop

    # wayland tools
    pkgs.wlr-randr
    pkgs.wl-clipboard
    pkgs.wl-clip-persist
    pkgs.cliphist

    # system services
    pkgs.polkit_gnome

    # desktop integration
    pkgs.xdg-utils

    # notifications/display
    pkgs.libnotify
    pkgs.wlsunset
    pkgs.grim
    pkgs.slurp

    # hardware management
    pkgs.brightnessctl

    # input
    pkgs.libinput-gestures
    pkgs.libinput

    # bluetooth
    pkgs.bluez
    pkgs.bluez-tools
    pkgs.blueman

    # audio
    pkgs.pavucontrol
    pkgs.pamixer
    pkgs.playerctl

    # media/utilities
    pkgs.dpms-off

    # custom scripts
    (pkgs.callPackage ./scripts/spotify-spicetified.nix { })

    pkgs.obsidian

    pkgs.zed-editor

    pkgs.wayland-pipewire-idle-inhibit

    (pkgs.prismlauncher.override {
      jdks = [ pkgs.jdk21 ];
    })
  ];

  programs.dconf.enable = true;
  services.dbus.enable = true;
  services.gvfs.enable = true;
  security.pam.services.swaylock = { };
  security.rtkit.enable = true;
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

  programs.gpu-screen-recorder.enable = true;
  services.flatpak.enable = true;

  programs.steam = {
    enable = true;
  };

  # GRAPHICS / DISPLAY MANAGER ----------------------------------------
  services.greetd.enable = true;

  # mango compositor requirements
  programs.xwayland.enable = true;
  services.graphical-desktop.enable = true;
  services.speechd.enable = false;

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
        "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
        # wlr does not have this interface
        "org.freedesktop.impl.portal.Inhibit" = [ ];
      };
    };
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
      xdg-desktop-portal-gtk
    ];
    wlr = {
      enable = true;
      settings.screencast = {
        chooser_type = "simple";
        chooser_cmd = "${pkgs.slurp}/bin/slurp -f 'Monitor: %o' -or";
        max_fps = 60;
      };
    };
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
