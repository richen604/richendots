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
  };

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
      # todo: wrap vscode w/ portable mode?
      xdg.config.files."Code/User/settings.json".source = pkgs.writeText "vscode-settings.json" ''
         {
          "workbench.colorTheme": "Tokyo Night",
          "window.menuBarVisibility": "toggle",
          "editor.fontSize": 15,
          "editor.scrollbar.vertical": "hidden",
          "editor.scrollbar.verticalScrollbarSize": 0,
          "security.workspace.trust.untrustedFiles": "newWindow",
          "security.workspace.trust.startupPrompt": "never",
          "security.workspace.trust.enabled": false,
          "editor.minimap.side": "left",
          "editor.fontFamily": "'Gohu Font 14 Nerd Font', 'monospace', monospace",
          "extensions.autoUpdate": false,
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
          "markdownlint.config": {
            "MD033": {
              "allowed_elements": [
                "nobr",
                "sup",
                "a",
                "div",
                "img",
                "br",
                "video",
                "kbd",
                "sub",
                "section",
                "details",
                "summary"
              ]
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

  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      looking-glass-obs
      obs-pipewire-audio-capture
    ];
    enableVirtualCamera = true;
  };
  programs.vscode = {
    enable = true;
    extensions = [
      pkgs.vscode-extensions.aaron-bond.better-comments
      pkgs.vscode-extensions.bierner.markdown-mermaid
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
      pkgs.vscode-extensions.ms-python.python
      pkgs.vscode-extensions.ms-vscode-remote.remote-ssh
      pkgs.vscode-extensions.redhat.vscode-yaml
      pkgs.vscode-extensions.saoudrizwan.claude-dev
      pkgs.vscode-extensions.streetsidesoftware.code-spell-checker
      pkgs.vscode-extensions.tamasfe.even-better-toml
      pkgs.vscode-extensions.timonwong.shellcheck
      pkgs.vscode-extensions.yoavbls.pretty-ts-errors
      pkgs.vscode-extensions.yzhang.markdown-all-in-one
      pkgs.vscode-extensions.ziglang.vscode-zig
      pkgs.vscode-extensions.gruntfuggly.todo-tree
    ];
  };

  qt = {
    enable = true;
    platformTheme = "gtk2";
    style = "adwaita-dark";
  };
  programs.dconf.profiles.user.databases = [
    {
      settings = {
        "org/gnome/desktop/interface" = {
          gtk-theme = "catppuccin-mocha-green-compact";
          color-scheme = "prefer-dark";
          font-name = "Gohu Font 14 Nerd Font";
          cursor-theme = "Bibata-Modern-Ice";
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

  services.flatpak.enable = true;

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
  };

  xdg.mime.defaultApplications = {
    "text/plain" = "org.kde.dolphin.desktop";
    "inode/directory" = "org.kde.dolphin.desktop";
    "application/pdf" = "org.mozilla.firefox.desktop";
    "text/html" = "org.mozilla.firefox.desktop";
    "x-scheme-handler/http" = "org.mozilla.firefox.desktop";
    "x-scheme-handler/https" = "org.mozilla.firefox.desktop";
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

    pkgs.kdePackages.kdeconnect-kde
    richenLib.wrappers.mango
    richenLib.wrappers.kitty
    richenLib.wrappers.zsh
    richenLib.wrappers.swaybg
    richenLib.wrappers.waybar
    richenLib.wrappers.swaync
    richenLib.wrappers.vicinae
    richenLib.wrappers.satty
    pkgs.vesktop
    pkgs.kdePackages.dolphin
    pkgs.fastfetch
    # todo: wrap git
    pkgs.git
    # todo: wrap firefox
    pkgs.firefox
    # todo: wrap neovim
    pkgs.neovim
    # todo: wrap tmux
    pkgs.tmux
    pkgs.less

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
    pkgs.wayland # for wayland support
    pkgs.egl-wayland # for wayland support
    pkgs.xwayland # for x11 support
    pkgs.gobject-introspection # for python packages
    pkgs.trash-cli # cli to manage trash files
    pkgs.gawk # awk implementation
    pkgs.coreutils # coreutils implementation
    pkgs.bash-completion # Add bash-completion package
    pkgs.libnotify
    pkgs.wlsunset
    pkgs.grim
    pkgs.slurp
    pkgs.firefox
    pkgs.bibata-cursors
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

    # qt deps
    pkgs.kdePackages.qt6ct
    pkgs.kdePackages.qtbase
    pkgs.kdePackages.qtwayland
    pkgs.kdePackages.qtstyleplugin-kvantum
    pkgs.kdePackages.breeze-icons
    pkgs.kdePackages.qtimageformats
    pkgs.kdePackages.qtsvg
    pkgs.kdePackages.qtwayland
    pkgs.kdePackages.qtimageformats # Image format support for Qt5
    pkgs.kdePackages.ffmpegthumbs # Video thumbnail support
    pkgs.kdePackages.kde-cli-tools # KDE command line utilities
    pkgs.kdePackages.kdegraphics-thumbnailers # KDE graphics thumbnails
    pkgs.kdePackages.kimageformats # Additional image format support for KDE
    pkgs.kdePackages.qtsvg # SVG support
    pkgs.kdePackages.kio # KDE I/O framework
    pkgs.kdePackages.kio-extras # Additional KDE I/O protocols
    pkgs.kdePackages.kwayland # KDE Wayland integration

    # gtk deps
    pkgs.gtk3
    pkgs.gtk4
    pkgs.glib
    pkgs.gsettings-desktop-schemas
    pkgs.gnome-settings-daemon
    pkgs.gnome-tweaks
    pkgs.gnomeExtensions.window-gestures
    pkgs.nwg-look
    pkgs.adwaita-icon-theme
    pkgs.emote

    pkgs.spicetify-cli
    pkgs.tealdeer

    # TODO: fix reboot-to and move this somewhere else
    (pkgs.writeScriptBin "reboot-to" ''
      #!/usr/bin/env bash

      if [ "$EUID" -ne 0 ]; then
        echo "Please run as root"
        exit 1
      fi

      # Get all GRUB entries
      entries=$(grep -E "menuentry ['\"].*['\"]" /boot/grub/grub.cfg | sed -E "s/menuentry ['\"](.*?)['\"].*/\1/")

      if [ "$1" = "list" ]; then
        echo "$entries" | nl
        exit 0
      fi

      # If no argument provided, use fzf to select
      if [ -z "$1" ]; then
        selected=$(echo "$entries" | ${pkgs.fzf}/bin/fzf --prompt="Select boot entry: ")
      else
        selected=$1
      fi

      if [ -n "$selected" ]; then
        grub-reboot "$selected"
        echo "System will reboot to '$selected' on next boot"
        echo "Run 'reboot' to restart now"
      else
        echo "No entry selected"
        exit 1
      fi
    '')
    pkgs.cpufrequtils

    pkgs.dpms-off
    pkgs.kdePackages.kdenetwork-filesharing
    # python stuff
    pkgs.uv

    # gaming
    pkgs.steam-run
    pkgs.protonup-qt

    # dev
    pkgs.pnpm
    pkgs.nodePackages.npm
    pkgs.fnm
    pkgs.godot
    pkgs.gdtoolkit_4
  ];

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
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
    localNetworkGameTransfers.openFirewall = true;
    protontricks.enable = true;
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

  # FONTS --------------------------------------------------------------
  fonts = {
    fontDir.enable = true;
    enableDefaultPackages = true;
    packages = with pkgs; [
      nerd-fonts.gohufont
      terminus_font
    ];
    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [ "Gohu Font 14 Nerd Font" ];
        sansSerif = [ "Gohu Font 14 Nerd Font" ];
        serif = [ "Gohu Font 14 Nerd Font" ];
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
        user = "richen";
      };
    };
  };

  # mango compositor requirements
  programs.xwayland.enable = lib.mkDefault true;
  services.graphical-desktop.enable = lib.mkDefault true;

  # xdg portal configuration
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
    xdgOpenUsePortal = true;
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
