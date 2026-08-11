{
  config,
  lib,
  richenLib,
  pkgs,
  ...
}:
let
  mangoConfig = pkgs.writeText "config.conf" richenLib.wrappers.mango-fern.config.content;
  mangoReloadConfig = pkgs.writeShellScript "mango-reload-config" ''
    ${richenLib.wrappers.mango-fern}/bin/mmsg dispatch reload_config || true
  '';
  # minecraft often doesnt close properly when exiting and will leave a stale java process
  prismLauncher = pkgs.writeShellApplication {
    name = "prism-launcher";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.flatpak
      pkgs.jq
      pkgs.procps
      richenLib.wrappers.mango-fern
    ];
    text = ''
      declare -A seen_window
      declare -A missing_since

      flatpak run org.prismlauncher.PrismLauncher "$@" &
      flatpak_pid=$!

      while kill -0 "$flatpak_pid" 2>/dev/null; do
        sleep 5
        clients="$(mmsg get all-clients 2>/dev/null)" || continue
        mapfile -t game_pids < <(pgrep -f '[o]rg.prismlauncher.EntryPoint' || true)

        for pid in "''${game_pids[@]}"; do
          if jq -e --argjson pid "$pid" 'any(.clients[]; .pid == $pid)' <<<"$clients" >/dev/null; then
            seen_window[$pid]=1
            unset 'missing_since[$pid]'
            continue
          fi

          if [[ -n "''${seen_window[$pid]:-}" ]]; then
            now="$(date +%s)"
            missing_since[$pid]="''${missing_since[$pid]:-$now}"
            if ((now - missing_since[$pid] >= 30)); then
              flatpak kill org.prismlauncher.PrismLauncher
              unset 'seen_window[$pid]' 'missing_since[$pid]'
              break
            fi
          fi
        done
      done

      wait "$flatpak_pid"
    '';
  };
in
{
  imports = [
    (import ../../wrappers/mango/_session.nix {
      inherit pkgs richenLib;
      mangoPackage = richenLib.wrappers.mango-fern;
      waybarPackage = richenLib.wrappers.waybar;
      swayidlePackage = richenLib.wrappers.swayidle;
      extraWantedServices = [ "sunshine.service" ];
    })
  ];

  environment.systemPackages = [
    richenLib.wrappers.mango-fern
    richenLib.wrappers.swaylock
    richenLib.wrappers.swayidle
    richenLib.wrappers.waybar
  ];

  systemd.user.services.sunshine = {
    wantedBy = lib.mkForce [ "mango-session.target" ];
    partOf = lib.mkForce [ "graphical-session.target" ];
    after = lib.mkForce [ "graphical-session.target" ];
    wants = lib.mkForce [ ];
  };

  hjem.users.richen = {
    files.".config/mango/config.conf".source = mangoConfig;
    files.".local/share/applications/org.prismlauncher.PrismLauncher.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Prism Launcher
      Comment=Custom Minecraft launcher
      Icon=org.prismlauncher.PrismLauncher
      Exec=${prismLauncher}/bin/prism-launcher %U
      Categories=Game;
      Terminal=false
    '';

    systemd.services.mango-reload-config = {
      description = "Reload Mango config";
      wantedBy = [ "mango-session.target" ];
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = mangoReloadConfig;
      };
      restartTriggers = [ config.hjem.users.richen.files.".config/mango/config.conf".source ];
    };
  };

  xdg.portal.configPackages = [
    richenLib.wrappers.mango-fern
  ];
}
