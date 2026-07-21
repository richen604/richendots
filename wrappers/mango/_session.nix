{
  pkgs,
  lib ? pkgs.lib,
  richenLib,
  mangoPackage,
  waybarPackage,
  swayidlePackage,
  vicinaePackage ? richenLib.wrappers.vicinae,
  extraWantedServices ? [ ],
  ...
}:
let
  home = "/home/${richenLib.vars.username}";
  sessionPath = lib.concatStringsSep ":" [
    "/run/wrappers/bin"
    "${home}/.local/share/flatpak/exports/bin"
    "/var/lib/flatpak/exports/bin"
    "${home}/.nix-profile/bin"
    "/nix/profile/bin"
    "${home}/.local/state/nix/profile/bin"
    "/etc/profiles/per-user/${richenLib.vars.username}/bin"
    "/nix/var/nix/profiles/default/bin"
    "/run/current-system/sw/bin"
  ];

  mangoStartSession = pkgs.writeShellScriptBin "mango-start-session" ''
    ${pkgs.systemd}/bin/systemctl --user import-environment \
      WAYLAND_DISPLAY \
      DISPLAY \
      XDG_CURRENT_DESKTOP \
      XDG_SESSION_TYPE \
      XDG_DATA_HOME \
      XDG_DATA_DIRS \
      XDG_CONFIG_HOME \
      XDG_CONFIG_DIRS \
      NIX_XDG_DESKTOP_PORTAL_DIR \
      MANGO_INSTANCE_SIGNATURE
    ${pkgs.systemd}/bin/systemctl --user start mango-session.target
  '';

  partOfMangoSession = {
    partOf = [ "mango-session.target" ];
    after = [ "mango-session.target" ];
    wantedBy = [ "mango-session.target" ];
  };

  simpleSessionService =
    execStart:
    lib.recursiveUpdate partOfMangoSession {
      serviceConfig = {
        ExecStart = execStart;
        Restart = "on-failure";
        RestartSec = 2;
      };
    };
in
{
  environment.systemPackages = [ mangoStartSession ];

  systemd.user.targets.mango-session = {
    description = "Mango graphical session";
    wants = [
      "waybar.service"
      "swayidle.service"
      "swaync.service"
      "vicinae.service"
      "swaybg.service"
      "wl-clip-persist.service"
      "cliphist-text.service"
      "cliphist-image.service"
      "wayland-pipewire-idle-inhibit.service"
      "wlsunset.service"
      "polkit-gnome-authentication-agent.service"
      "blueman-applet.service"
      "keepassxc.service"
      "equibop.service"
      "spotify.service"
      "yubikey-touch-detector.service"
    ]
    ++ extraWantedServices;
  };

  systemd.user.paths.mango-reload-config = {
    wantedBy = [ "mango-session.target" ];
    pathConfig = {
      PathChanged = "%h/.config/mango/config.conf";
      Unit = "mango-reload-config.service";
    };
  };

  systemd.user.services = {
    mango-reload-config = {
      description = "Reload Mango config";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${mangoPackage}/bin/mmsg dispatch reload_config";
      };
    };

    waybar = lib.recursiveUpdate partOfMangoSession {
      description = "Highly customizable Wayland bar for wlroots compositors";
      documentation = [ "https://github.com/Alexays/Waybar/wiki/" ];
      serviceConfig = {
        ExecStart = "${waybarPackage}/bin/waybar";
        ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID";
        Environment = "PATH=${sessionPath}";
        Restart = "on-failure";
      };
    };

    swayidle = lib.recursiveUpdate partOfMangoSession {
      description = "Idle manager for Wayland";
      serviceConfig = {
        ExecStart = "${swayidlePackage}/bin/swayidle";
        Restart = "on-failure";
      };
    };

    wayland-pipewire-idle-inhibit = lib.recursiveUpdate partOfMangoSession {
      description = "Wayland idle inhibitor for active PipeWire streams";
      serviceConfig = {
        ExecStart = "${pkgs.wayland-pipewire-idle-inhibit}/bin/wayland-pipewire-idle-inhibit";
        Restart = "on-failure";
        RestartSec = 2;
      };
    };

    waybar-manual-idle-inhibit = {
      description = "Manual Wayland idle inhibitor controlled by Waybar";
      partOf = [ "mango-session.target" ];
      after = [ "mango-session.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.wlinhibit}/bin/wlinhibit";
        Restart = "no";
      };
    };

    swaync = lib.recursiveUpdate partOfMangoSession {
      description = "Swaync notification daemon";
      documentation = [ "https://github.com/ErikReider/SwayNotificationCenter" ];
      unitConfig.ConditionEnvironment = "WAYLAND_DISPLAY";
      serviceConfig = {
        Type = "dbus";
        BusName = "org.freedesktop.Notifications";
        ExecStart = "${richenLib.wrappers.swaync}/bin/swaync";
        ExecReload = "${richenLib.wrappers.swaync}/bin/swaync-client --reload-config ; ${richenLib.wrappers.swaync}/bin/swaync-client --reload-css";
        Restart = "on-failure";
      };
    };

    vicinae = lib.recursiveUpdate partOfMangoSession {
      description = "Vicinae Launcher Daemon";
      documentation = [ "https://docs.vicinae.com" ];
      requires = [ "dbus.socket" ];
      serviceConfig = {
        ExecStart = "${vicinaePackage}/bin/vicinae server --replace";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        Environment = "PATH=${sessionPath}";
        Restart = "always";
        RestartSec = 60;
        KillMode = "process";
      };
    };

    swaybg = simpleSessionService "${richenLib.wrappers.swaybg}/bin/swaybg";

    wl-clip-persist = simpleSessionService "${pkgs.wl-clip-persist}/bin/wl-clip-persist --clipboard regular --reconnect-tries 0";

    cliphist-text = simpleSessionService "${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist store";

    cliphist-image = simpleSessionService "${pkgs.wl-clipboard}/bin/wl-paste --type image --watch ${pkgs.cliphist}/bin/cliphist store";

    wlsunset = simpleSessionService "${richenLib.wrappers.wlsunset}/bin/wlsunset";

    polkit-gnome-authentication-agent = simpleSessionService "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";

    blueman-applet = lib.recursiveUpdate partOfMangoSession {
      description = "Bluetooth management applet";
      serviceConfig = {
        Restart = "on-failure";
        RestartSec = 2;
      };
    };

    keepassxc = lib.recursiveUpdate partOfMangoSession {
      description = "KeePassXC password manager";
      serviceConfig = {
        ExecStart = "${richenLib.wrappers.keepassxc}/bin/keepassxc";
        Restart = "no";
      };
    };

    equibop = lib.recursiveUpdate partOfMangoSession {
      description = "Equibop chat client";
      serviceConfig = {
        ExecStart = "${pkgs.lib.getExe pkgs.equibop} --ozone-platform=wayland";
        Environment = "LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib ]}";
        Restart = "no";
      };
    };

    spotify = lib.recursiveUpdate partOfMangoSession {
      description = "Spotify Flatpak client";
      after = partOfMangoSession.after ++ [ "equibop.service" ];
      serviceConfig = {
        ExecStart = "${pkgs.flatpak}/bin/flatpak run --user com.spotify.Client";
        Restart = "no";
      };
    };

    yubikey-touch-detector = simpleSessionService "${pkgs.yubikey-touch-detector}/bin/yubikey-touch-detector -libnotify";
  };
}
