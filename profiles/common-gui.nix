{
  pkgs,
  inputs,
  richenLib,
  ...
}:
{

  imports = [
    inputs.hjem.nixosModules.default
  ];

  # packages
  environment.systemPackages = [
    richenLib.wrappers.kitty
    richenLib.wrappers.zsh
    richenLib.wrappers.swaybg
    richenLib.wrappers.waybar
    richenLib.wrappers.swaync
    richenLib.wrappers.vicinae
    richenLib.wrappers.satty
    richenLib.wrappers.firefox
    richenLib.wrappers.keepassxc
    richenLib.wrappers.git
    richenLib.wrappers.udiskie

    # cursor, icon, gtk themes
    pkgs.bibata-cursors
    (pkgs.catppuccin-papirus-folders.override {
      accent = "green";
      flavor = "mocha";
    })
    (pkgs.catppuccin-gtk.override {
      accents = [ "green" ];
      size = "compact";
      variant = "mocha";
    })
    pkgs.hicolor-icon-theme

    # qt6 deps
    pkgs.kdePackages.qt6ct
    pkgs.kdePackages.qtbase
    pkgs.kdePackages.qtwayland
    pkgs.kdePackages.qtstyleplugin-kvantum
    pkgs.kdePackages.breeze-icons
    pkgs.kdePackages.qtimageformats
    pkgs.kdePackages.qtsvg
    pkgs.kdePackages.ffmpegthumbs
    pkgs.kdePackages.kde-cli-tools
    pkgs.kdePackages.kdegraphics-thumbnailers
    pkgs.kdePackages.kimageformats
    pkgs.kdePackages.kio
    pkgs.kdePackages.kio-fuse
    pkgs.kdePackages.kio-extras
    pkgs.kdePackages.kwayland
    pkgs.kdePackages.plasma-integration
    pkgs.kdePackages.dolphin-plugins

    # qt5 deps (for apps still using Qt5)
    pkgs.libsForQt5.qt5.qtbase
    pkgs.libsForQt5.qt5.qtwayland
    pkgs.libsForQt5.qtstyleplugin-kvantum

    # dolphin
    pkgs.kdePackages.dolphin
    pkgs.icoutils
    pkgs.kdePackages.kdesdk-thumbnailers
    pkgs.libappimage
    pkgs.resvg
    pkgs.taglib

    # gtk deps
    pkgs.gtk3
    pkgs.gtk4
    pkgs.glib
    pkgs.nwg-look
    pkgs.adwaita-icon-theme

    # media apps
    pkgs.spicetify-cli

    # social apps
    pkgs.vesktop
    pkgs.equicord

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
    pkgs.kdePackages.ark

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

    # gaming
    pkgs.steam-run

    # custom scripts
    (pkgs.callPackage ./scripts/spotify-spicetified.nix { })

    pkgs.obsidian
  ];

  programs.dconf.enable = true;
  services.dbus.enable = true;
  services.upower.enable = true;
  services.libinput.enable = true;
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
    ];
  };
  # todo: this may be better placed in common.nix
  systemd.services.NetworkManager-wait-online.enable = false;

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
    QT_QPA_PLATFORMTHEME = "qt6ct";
    QT_STYLE_OVERRIDE = "kvantum";
    GTK_BACKEND = "wayland;x11";
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
  };

  # default apps
  xdg.mime.defaultApplications = {
    "text/plain" = "org.kde.dolphin.desktop";
    "inode/directory" = "org.kde.dolphin.desktop";
    "application/pdf" = "firefox.desktop";
    "text/html" = "firefox.desktop";
    "x-scheme-handler/http" = "firefox.desktop";
    "x-scheme-handler/https" = "firefox.desktop";
  };

  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true;
  };
  services.flatpak.enable = true;

  # gaming
  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };
  programs.steam = {
    enable = true;
    extraPackages = with pkgs; [
      gamemode
      gamescope
    ];
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
        # todo: apparently these can go to /share/Kvantum
        ".config/Kvantum".source = ./config/Kvantum;
        ".config/kdeglobals".source = ./config/kdeglobals;
        ".config/qt6ct".source = ./config/qt6ct;
        ".config/vesktop/themes/system24-grove.css".source = ./config/vesktop/system24-grove.css;
        # todo: future: wrap vscode w/ portable mode?
        ".config/Code/User/settings.json" = {
          type = "copy";
          permissions = "0644";
          source = ./config/vscode/settings.json;
        };
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

  # editor
  programs.vscode = {
    enable = true;
    extensions = [
      pkgs.vscode-extensions.aaron-bond.better-comments
      pkgs.vscode-extensions.bierner.markdown-preview-github-styles
      pkgs.vscode-extensions.catppuccin.catppuccin-vsc-icons
      pkgs.vscode-extensions.davidanson.vscode-markdownlint
      pkgs.vscode-extensions.dbaeumer.vscode-eslint
      pkgs.vscode-extensions.ecmel.vscode-html-css
      pkgs.vscode-extensions.enkia.tokyo-night
      pkgs.vscode-extensions.esbenp.prettier-vscode
      pkgs.vscode-extensions.geequlim.godot-tools
      pkgs.vscode-extensions.github.copilot
      pkgs.vscode-extensions.github.vscode-github-actions
      pkgs.vscode-extensions.github.vscode-pull-request-github
      pkgs.vscode-extensions.ibm.output-colorizer
      pkgs.vscode-extensions.jnoortheen.nix-ide
      pkgs.vscode-extensions.leonardssh.vscord
      pkgs.vscode-extensions.mads-hartmann.bash-ide-vscode
      pkgs.vscode-extensions.mkhl.shfmt
      pkgs.vscode-extensions.ms-vscode-remote.remote-ssh
      pkgs.vscode-extensions.redhat.vscode-yaml
      pkgs.vscode-extensions.tamasfe.even-better-toml
      pkgs.vscode-extensions.timonwong.shellcheck
      pkgs.vscode-extensions.yoavbls.pretty-ts-errors
      pkgs.vscode-extensions.yzhang.markdown-all-in-one
      pkgs.vscode-extensions.ziglang.vscode-zig
      pkgs.vscode-extensions.gruntfuggly.todo-tree
      pkgs.vscode-extensions.rooveterinaryinc.roo-cline
    ];
  };
}
