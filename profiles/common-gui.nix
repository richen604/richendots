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

    # qt deps
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
  ];

  programs.dconf.enable = true;
  services.dbus.enable = true;
  services.upower.enable = true;
  services.libinput.enable = true;
  services.gvfs.enable = true;
  security.pam.services.swaylock = { };
  security.rtkit.enable = true;

  # boot
  boot = {
    plymouth = {
      enable = true;
      theme = "rings";
      themePackages = with pkgs; [
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
      "console=/dev/null"
      "boot.shell_on_fail"
      "udev.log_priority=3"
      "rd.systemd.show_status=auto"
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
          cursor-size = "24";
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
    XCURSOR_SIZE = "24";
    MOZ_ENABLE_WAYLAND = "1";
    GTK_THEME = "catppuccin-mocha-green-compact";
    QT_QPA_PLATFORM = "wayland;xcb";
    GTK_BACKEND = "wayland;x11";
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    QT_QPA_PLATFORMTHEME = "qt6ct";
    QT_STYLE_OVERRIDE = "kvantum";
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
  };

  # GRAPHICS / DISPLAY MANAGER ----------------------------------------
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd mango";
        user = "greeter";
      };
      initial_session = {
        command = "mango";
        user = "richen";
      };
    };
  };

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
        # todo: future: wrap vscode w/ portable mode?
        ".config/Code/User/settings.json" = {
          type = "copy";
          permissions = "0644";
          source = pkgs.writeText "vscode-settings.json" ''
             {
              "workbench.colorTheme": "Tokyo Night",
              "window.menuBarVisibility": "toggle",
              "editor.fontSize": 17,
              "editor.fontWeight": "700",
              "editor.lineHeight": 1.3,
              "editor.scrollbar.vertical": "hidden",
              "editor.scrollbar.verticalScrollbarSize": 0,
              "security.workspace.trust.untrustedFiles": "newWindow",
              "security.workspace.trust.startupPrompt": "never",
              "security.workspace.trust.enabled": false,
              "editor.minimap.side": "left",
              "editor.fontFamily": "'GohuFont uni14 Nerd Font Propo'",
              "extensions.autoUpdate": true,
              "workbench.statusBar.visible": true,
              "terminal.external.linuxExec": "kitty",
              "terminal.explorerKind": "both",
              "terminal.sourceControlRepositoriesKind": "both",
              "telemetry.telemetryLevel": "off",
              "workbench.activityBar.location": "top",
              "window.customTitleBarVisibility": "auto",
              "workbench.iconTheme": "catppuccin-mocha",
              "editor.cursorSmoothCaretAnimation": "on",
              "editor.autoIndent": "full",
              "editor.formatOnSave": true,
              "nix.enableLanguageServer": true,
              "nix.formatterPath": "nixfmt",
              "nix.serverPath": "nil",
              "nix.hiddenLanguageServerErrors": [
                "textDocument/definition",
                "textDocument/formatting",
                "textDocument/documentSymbol"
              ],
              "nix.serverSettings": {
                "nil": {
                  "formatting": {
                    "command": ["nixfmt"]
                  }
                }
              },
              "workbench.sideBar.location": "right",
              "git.enableSmartCommit": true,
              "github.copilot.nextEditSuggestions.enabled": true,
              "todo-tree.general.tags": [
                "BUG",
                "HACK",
                "FIXME",
                "TODO",
                "XXX",
                "[ ]",
                "[x]",
                "todo",
                "fixme",
                "bug"
              ],
              "editor.minimap.enabled": false
            }
          '';
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
