{
  config,
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
      declare -A existing_instance
      game_started=false
      stale_game=false
      startup_deadline=$((SECONDS + 60))
      watchdog_deadline=$((SECONDS + 12 * 60 * 60))

      while read -r instance application; do
        if [[ "$application" == org.prismlauncher.PrismLauncher ]]; then
          existing_instance[$instance]=1
        fi
      done < <(timeout 2 flatpak ps --columns=instance,application 2>/dev/null || true)

      flatpak run org.prismlauncher.PrismLauncher "$@" &
      flatpak_pid=$!

      is_descendant() {
        local pid=$1 ancestor=$2 stat ppid

        while ((pid > 1)); do
          [[ "$pid" == "$ancestor" ]] && return 0
          [[ -r "/proc/$pid/stat" ]] || return 1
          read -r stat < "/proc/$pid/stat"
          read -r _ ppid _ <<< "''${stat##*) }"
          pid=$ppid
        done
        return 1
      }

      instance=
      instance_pid=
      while ((SECONDS < startup_deadline)); do
        while read -r candidate candidate_pid application; do
          [[ "$application" == org.prismlauncher.PrismLauncher ]] || continue
          [[ -z "''${existing_instance[$candidate]:-}" ]] || continue
          if is_descendant "$candidate_pid" "$flatpak_pid"; then
            instance=$candidate
            instance_pid=$candidate_pid
            break 2
          fi
        done < <(timeout 2 flatpak ps --columns=instance,pid,application 2>/dev/null || true)

        kill -0 "$flatpak_pid" 2>/dev/null || break
        sleep 1
      done

      while [[ -n "$instance" ]] && ((SECONDS < watchdog_deadline)); do
        if ! kill -0 "$instance_pid" 2>/dev/null; then
          break
        fi
        if ! clients="$(timeout 2 mmsg get all-clients 2>/dev/null)"; then
          sleep 5
          continue
        fi
        game_pids=()
        while read -r pid; do
          [[ -r "/proc/$pid/cmdline" ]] || continue
          cmdline="$(tr '\0' ' ' < "/proc/$pid/cmdline")"
          if is_descendant "$pid" "$instance_pid" && [[ "$cmdline" == *org.prismlauncher.EntryPoint* ]]; then
            game_pids+=("$pid")
          fi
        done < <(pgrep -f '[o]rg.prismlauncher.EntryPoint' || true)

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
              if timeout 5 flatpak kill "$instance"; then
                stale_game=true
              fi
              break 2
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
    })
  ];

  environment.systemPackages = [
    richenLib.wrappers.mango-fern
    richenLib.wrappers.swaylock
    richenLib.wrappers.swayidle
    richenLib.wrappers.waybar
  ];

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
      partOf = [ "mango-session.target" ];
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
