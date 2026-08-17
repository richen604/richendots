{
  config,
  lib,
  richenLib,
  pkgs,
  steamGameRun,
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
      game_started=false
      stale_game=false
      startup_deadline=$((SECONDS + 60))

      flatpak run org.prismlauncher.PrismLauncher "$@" &
      flatpak_pid=$!

      while true; do
        if ! clients="$(mmsg get all-clients 2>/dev/null)"; then
          sleep 5
          continue
        fi
        mapfile -t game_pids < <(pgrep -f '[o]rg.prismlauncher.EntryPoint' || true)

        if ((''${#game_pids[@]} == 0)); then
          if [[ "$game_started" == true ]] || ((SECONDS >= startup_deadline)); then
            break
          fi
          sleep 5
          continue
        fi

        game_started=true
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
              stale_game=true
              break
            fi
          fi
        done

        [[ "$stale_game" == false ]] || break
        sleep 5
      done

      wait "$flatpak_pid" || [[ "$game_started" == true ]]
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
      Exec=${steamGameRun}/bin/steam-game-run ${prismLauncher}/bin/prism-launcher %U
      Categories=Game;
      Terminal=false
    '';
    files.".local/share/applications/smooth-matcha.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Smooth Matcha
      Comment=Launch the Smooth Matcha modpack
      Icon=/home/${richenLib.vars.username}/.var/app/org.prismlauncher.PrismLauncher/data/PrismLauncher/icons/curseforge_639209545400856710.png
      Exec=${steamGameRun}/bin/steam-game-run ${prismLauncher}/bin/prism-launcher --launch "Smooth Matcha"
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
