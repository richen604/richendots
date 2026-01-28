{
  pkgs,
  lib,
  inputs,
  hostname,
  richenLib,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    inputs.hjem.nixosModules.default
  ];

  # turn off bloat
  documentation = {
    enable = false;
    man.enable = false;
    info.enable = false;
    doc.enable = false;
    dev.enable = false;
    nixos.enable = false;
  };

  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true;
  };
  services.flatpak.enable = true;

  # docker
  virtualisation.docker.enable = true;
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  # gaming
  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };
  programs.steam = {
    enable = true;
  };

  environment.etc."mango/config.conf".source =
    pkgs.writeText "config.conf" richenLib.wrappers.mango-desktop.passthru.config;

  # USERS -------------------------------------------------------------
  users.users.richen = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "video"
      "input"
      "networkmanager"
      # todo: should be in a dev module
      "docker"
    ];
    home = "/home/richen";
    initialPassword = "test";
    createHome = true;
    shell = "${pkgs.lib.getExe richenLib.wrappers.zsh}";
  };
  users.defaultUserShell = "${pkgs.lib.getExe richenLib.wrappers.zsh}";

  xdg.icons.fallbackCursorThemes = [ "Bibata-Modern-Ice" ];

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

  boot = {
    loader.grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      useOSProber = true;
      extraEntries = ''
        menuentry "UEFI Firmware Settings" {
          fwsetup
        }
      '';
    };
  };

  time.timeZone = "America/Vancouver";
  i18n.defaultLocale = "en_CA.UTF-8";
  networking.hostName = hostname;
  system.stateVersion = "26.05";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.settings.allow-import-from-derivation = false;

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
  services.gvfs.enable = true;
  security.polkit.enable = true;
  security.pam.services.swaylock = { };
  security.rtkit.enable = true;

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

  xdg.mime.defaultApplications = {
    "text/plain" = "org.kde.dolphin.desktop";
    "inode/directory" = "org.kde.dolphin.desktop";

    "application/pdf" = "firefox.desktop";
    "text/html" = "firefox.desktop";
    "x-scheme-handler/http" = "firefox.desktop";
    "x-scheme-handler/https" = "firefox.desktop";
  };

  # PACKAGES ---------------------------------------------------------
  environment.systemPackages = [
    pkgs.bibata-cursors
    # todo: maybe tela-green instead
    (pkgs.catppuccin-papirus-folders.override {
      accent = "green";
      flavor = "mocha";
    })
    # todo: greenify gtk host + drv
    (pkgs.catppuccin-gtk.override {
      accents = [ "green" ];
      size = "compact";
      variant = "mocha";
    })

    pkgs.nixfmt-rfc-style
    pkgs.nil
    # todo: custom scripts with nom post flakes?
    # pkgs.nix-output-monitor

    richenLib.wrappers.mango-desktop
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

    pkgs.bat # cat alternative
    pkgs.eza # ls alternative
    pkgs.tree # directory tree viewer
    pkgs.htop # interactive process viewer
    # todo: remove vesktop when migrated to equicord
    pkgs.vesktop
    pkgs.equicord
    pkgs.fastfetch
    # todo: wrap neovim
    pkgs.neovim
    # todo: wrap tmux
    pkgs.tmux
    pkgs.less
    pkgs.wlogout

    pkgs.wlr-randr # Wayland display configuration tool
    pkgs.killall # Process termination utility
    pkgs.wl-clipboard # Wayland clipboard utilities
    pkgs.wl-clip-persist # Keep Wayland clipboard even after programs close
    pkgs.cliphist # clipboard manager
    pkgs.gnumake # Build automation tool
    pkgs.fzf # command line fuzzy finder
    pkgs.polkit_gnome # authentication agent for privilege escalation
    pkgs.dbus # inter-process communication daemon
    pkgs.upower # power management/battery status daemon
    pkgs.mesa # OpenGL implementation and GPU drivers
    pkgs.dconf # configuration storage system
    pkgs.dconf-editor # dconf editor
    pkgs.xdg-utils # Collection of XDG desktop integration tools
    pkgs.desktop-file-utils # for updating desktop database
    pkgs.hicolor-icon-theme # Base fallback icon theme
    # todo: set xdg mine defaults for ark
    pkgs.kdePackages.ark # kde file archiver
    pkgs.trash-cli # cli to manage trash files
    pkgs.gawk # awk implementation
    pkgs.coreutils # coreutils implementation
    pkgs.bash-completion # Add bash-completion package
    pkgs.libnotify
    pkgs.wlsunset
    pkgs.grim
    pkgs.slurp
    pkgs.networkmanager
    pkgs.networkmanagerapplet
    pkgs.brightnessctl # screen brightness control
    pkgs.udiskie # manage removable media
    pkgs.ntfs3g # ntfs support
    pkgs.exfat # exFAT support
    pkgs.libinput-gestures # actions touchpad gestures using libinput
    pkgs.libinput # libinput library
    pkgs.lm_sensors # system sensors
    pkgs.pciutils # pci utils
    pkgs.bluez
    pkgs.bluez-tools
    pkgs.blueman
    pkgs.pipewire
    pkgs.wireplumber
    pkgs.pavucontrol
    pkgs.pamixer
    pkgs.playerctl
    pkgs.unzip
    pkgs.wf-recorder

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
    pkgs.spicetify-cli
    pkgs.tealdeer
    pkgs.kdePackages.kdeconnect-kde

    # Custom scripts
    (pkgs.callPackage ./scripts/reboot-to.nix { })
    pkgs.cpufrequtils

    pkgs.dpms-off
    # todo dev shells
    # python stuff
    # pkgs.uv
    # dev
    # pkgs.pnpm
    # pkgs.nodePackages.npm
    # pkgs.fnm
    # pkgs.godot
    # pkgs.gdtoolkit_4

    # gaming
    pkgs.steam-run

    # Spotify with Spicetify wrapper
    (pkgs.callPackage ./scripts/spotify-spicetified.nix { })
  ];

  environment.pathsToLink = [ "/share/zsh" ];

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

  # FONTS --------------------------------------------------------------

  environment.etc."gtk-3.0/gtk.css".text = ''
    label, entry, textview, button {
      font-weight: 600; 
    }
  '';

  environment.etc."gtk-4.0/gtk.css".text = ''
    label, entry, textview, button {
      font-weight: 600;
    }
  '';

  fonts = {
    fontDir.enable = true;
    enableDefaultPackages = true;
    packages = with pkgs; [
      nerd-fonts.gohufont
      terminus_font
    ];
    fontconfig = {
      enable = true;
      # fixes gohufont not having bold weights
      localConf = ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
        <fontconfig>
          <match target="font">
            <test name="family" compare="contains">
              <string>Gohu</string>
            </test>
            <edit name="embolden" mode="assign">
              <bool>true</bool>
            </edit>
          </match>
        </fontconfig>
      '';
      defaultFonts = {
        monospace = [ "GohuFont uni14 Nerd Font Propo" ];
        sansSerif = [ "GohuFont uni14 Nerd Font Propo" ];
        serif = [ "GohuFont uni14 Nerd Font Propo" ];
      };
    };
  };

  # GRAPHICS / DISPLAY MANAGER ----------------------------------------
  # Lightweight display manager configuration
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
  programs.xwayland.enable = lib.mkDefault true;
  services.graphical-desktop.enable = lib.mkDefault true;

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
    # configPackages = [ richenLib.wrappers.mango ];
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
