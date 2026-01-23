{
  pkgs,
  lib,
  inputs,
  hostname,
  richenLib,
  ...
}:
let

  wrappers = richenLib.wrappers { };
in
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
    shell = "${pkgs.lib.getExe wrappers.zsh}";
  };
  users.defaultUserShell = "${pkgs.lib.getExe wrappers.zsh}";

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

    wrappers.mango
    wrappers.kitty
    wrappers.zsh
    wrappers.swaybg
    wrappers.waybar
    wrappers.swaync
    wrappers.vicinae
    wrappers.satty
    wrappers.firefox
    wrappers.keepassxc
    wrappers.git
    wrappers.udiskie

    pkgs.bat # cat alternative
    pkgs.eza # ls alternative
    pkgs.tree # directory tree viewer
    pkgs.htop # interactive process viewer
    # todo: remove vesktop when migrated to equicord
    pkgs.vesktop
    pkgs.equicord
    pkgs.kdePackages.dolphin
    pkgs.fastfetch
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

    # file previews / thumbnailers
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

    # i don't want to add declarative flatpak, so here's a semi useful spotify wrapper
    # todo: spotify wrapped: grab exactly the configs required and apply them manually
    # todo: spotify wrapped: clean up vars
    (pkgs.writeShellScriptBin "spotify-spicetified" ''
      #!/usr/bin/env sh
      set -e

      APP_ID="com.spotify.Client"
      SPOTIFY_PATH="$HOME/.var/app/$APP_ID"
      SPICETIFY_DIR="$HOME/.config/spicetify"
      PREFS="$SPOTIFY_PATH/config/spotify/prefs"
      TIMEOUT=30

      echo "==> Checking Flathub repository..."
      ${pkgs.flatpak}/bin/flatpak remote-add --user --if-not-exists flathub \
        https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

      echo "==> Checking Spotify installation..."
      if ! ${pkgs.flatpak}/bin/flatpak info --user "$APP_ID" >/dev/null 2>&1; then
        echo "==> Installing Spotify from Flathub..."
        ${pkgs.flatpak}/bin/flatpak install --user -y flathub "$APP_ID"

        echo "==> Initializing Spotify to create config files..."
        ${pkgs.flatpak}/bin/flatpak run --user "$APP_ID"

        echo "==> Waiting for preferences file ($PREFS)..."
        ELAPSED=0
        while [ ! -f "$PREFS" ] && [ $ELAPSED -lt $TIMEOUT ]; do
          sleep 1
          ELAPSED=$((ELAPSED + 1))
        done


        echo "==> Configuring Spicetify..."
        ${pkgs.spicetify-cli}/bin/spicetify config prefs_path "$PREFS"

        echo "==> Creating backup and applying Spicetify..."
        ${pkgs.spicetify-cli}/bin/spicetify backup || true

        sleep 2

        echo "==> Installing Spicetify Marketplace..."
        # download uri
        releases_uri=https://github.com/spicetify/marketplace/releases
        if [ $# -gt 0 ]; then
          tag=$1
        else
          tag=$(curl -LsH 'Accept: application/json' $releases_uri/latest)
          tag=''${tag%\,\"update_url*}
          tag=''${tag##*tag_name\":\"}
          tag=''${tag%\"}
        fi

        tag=''${tag#v}

        echo "FETCHING Version $tag"

        download_uri=$releases_uri/download/v$tag/marketplace.zip
        default_color_uri="https://raw.githubusercontent.com/spicetify/marketplace/main/resources/color.ini"

        SPICETIFY_CONFIG_DIR="$SPICETIFY_CONFIG"
        if [ -z "$SPICETIFY_CONFIG_DIR" ]; then
          SPICETIFY_CONFIG_DIR="''${XDG_CONFIG_HOME:-$HOME/.config}/spicetify"
        fi
        INSTALL_DIR="$SPICETIFY_CONFIG_DIR/CustomApps"

        if [ ! -d "$INSTALL_DIR" ]; then
            echo "MAKING FOLDER  $INSTALL_DIR";
            mkdir -p "$INSTALL_DIR"
        fi

        TAR_FILE="$INSTALL_DIR/marketplace-dist.zip"

        echo "DOWNLOADING $download_uri"
        curl --fail --location --progress-bar --output "$TAR_FILE" "$download_uri"
        cd "$INSTALL_DIR"

        echo "EXTRACTING"
        unzip -q -d "$INSTALL_DIR/marketplace-tmp" -o "$TAR_FILE"

        cd "$INSTALL_DIR/marketplace-tmp"
        echo "COPYING"
        rm -rf "$INSTALL_DIR/marketplace/"
        mv "$INSTALL_DIR/marketplace-tmp/marketplace-dist" "$INSTALL_DIR/marketplace"

        echo "INSTALLING"
        cd "$INSTALL_DIR/marketplace"

        # Remove old custom app name if exists
        ${pkgs.spicetify-cli}/bin/spicetify config custom_apps marketplace

        # Color injection fix
        ${pkgs.spicetify-cli}/bin/spicetify config inject_css 1
        ${pkgs.spicetify-cli}/bin/spicetify config replace_colors 1

        current_theme=$(${pkgs.spicetify-cli}/bin/spicetify config current_theme)
        if [ ''${#current_theme} -le 3 ]; then
            echo "No theme selected, using placeholder theme"
            if [ ! -d "$SPICETIFY_CONFIG_DIR/Themes/marketplace" ]; then
                echo "MAKING FOLDER  $SPICETIFY_CONFIG_DIR/Themes/marketplace";
                mkdir -p "$SPICETIFY_CONFIG_DIR/Themes/marketplace"
            fi
            curl --fail --location --progress-bar --output "$SPICETIFY_CONFIG_DIR/Themes/marketplace/color.ini" "$default_color_uri"
            ${pkgs.spicetify-cli}/bin/spicetify config current_theme marketplace;
        fi

        echo "CLEANING UP"
        rm -rf "$TAR_FILE" "$INSTALL_DIR/marketplace-tmp/"

        echo "==> Applying Spictify TUI theme..."
        theme_url="https://raw.githubusercontent.com/AvinashReddy3108/spicetify-tui/master/tui"

        # Setup directories to download to
        spice_dir="$(dirname "$(${pkgs.spicetify-cli}/bin/spicetify -c)")"
        theme_dir="''${spice_dir}/Themes"

        # Make directories if needed
        mkdir -p "''${theme_dir}/tui"

        # Download latest tagged files into correct directory
        echo "Downloading spicetify-tui theme..."
        ${pkgs.curl}/bin/curl --silent --output "''${theme_dir}/tui/color.ini" "''${theme_url}/color.ini"
        ${pkgs.curl}/bin/curl --silent --output "''${theme_dir}/tui/user.css" "''${theme_url}/user.css"
        echo "Done"

        echo "Applying theme..."
        ${pkgs.spicetify-cli}/bin/spicetify config current_theme tui color_scheme CatppuccinMocha
        
        echo "Applying patches..."
        # Insert patches after existing [Patch] header since CLI doesn't support them
        CONFIG_FILE="$(${pkgs.spicetify-cli}/bin/spicetify -c)"
        sed -i '/\[Patch\]/a xpui.js_find_8008 = ,(\\w+=)56,\nxpui.js_repl_8008 = ,''${1}32', "$CONFIG_FILE"
        
        sleep 2

        echo "==> Applying Spicetify themes and extensions..."
        ${pkgs.spicetify-cli}/bin/spicetify apply

        echo "==> Setup complete!"
        exit 0
      fi

      echo "==> Launching Spotify..."
      exec ${pkgs.flatpak}/bin/flatpak run --user "$APP_ID"
    '')

  ];

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
    configPackages = [ wrappers.mango ];
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
