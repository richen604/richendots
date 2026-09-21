{
  hostvars,
  lib,
  pkgs,
  richenLib,
  ...
}:
let
  isFern = hostvars.hostname == "fern";
  replayDir = "$HOME/.local/share/replays";
  systemdReplayDir = "%h/.local/share/replays";
  unitNames = [
    "replay-buffer-primary.service"
  ]
  ++ lib.optionals isFern [
    "replay-buffer-left.service"
    "replay-buffer-right.service"
  ];
  sideUnitNames = lib.optionals isFern [
    "replay-buffer-left.service"
    "replay-buffer-right.service"
  ];
  unitsShell = lib.escapeShellArgs unitNames;
  sideUnitsShell = lib.escapeShellArgs sideUnitNames;
  refreshWaybar = "${pkgs.procps}/bin/pkill -RTMIN+10 waybar 2>/dev/null || true";

  mkReplaySaved =
    label:
    pkgs.writeShellApplication {
      name = "replay-saved-${label}";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.libnotify
      ];
      text = ''
        set -euo pipefail
        [[ "''${2:-}" == replay ]] || exit 0
        source="''${1:?missing path}"
        filename="$(basename "$source")"
        stem="''${filename%.*}"
        extension="''${filename##*.}"
        destination="${replayDir}/$stem-${label}.$extension"
        if [[ -e "$destination" ]]; then
          destination="${replayDir}/$stem-${label}-$(date +%s%N).$extension"
        fi
        mv -- "$source" "$destination"
        notify-send --urgency=low "Replay saved" "$(basename "$destination")"
      '';
    };

  mkReplayLaunch =
    {
      label,
      fps,
      bitrate,
      model ? null,
    }:
    let
      replaySaved = mkReplaySaved label;
      capture =
        if model == null then
          "monitor=screen"
        else
          ''
            monitor="$(wlr-randr --json | jq -r --arg model ${lib.escapeShellArg model} \
              'first(.[] | select(.enabled and .model == $model) | .name) // empty')"
            [[ -n "$monitor" ]] || {
              printf 'replay-buffer-${label}: monitor %s is unavailable\n' ${lib.escapeShellArg model} >&2
              exit 1
            }
          '';
    in
    pkgs.writeShellApplication {
      name = "replay-buffer-${label}";
      runtimeInputs = [
        pkgs.gpu-screen-recorder
        pkgs.jq
        pkgs.wlr-randr
      ];
      text = ''
        set -euo pipefail
        ${capture}
        exec gpu-screen-recorder \
          -w "$monitor" -c mp4 -f ${toString fps} -a default_output \
          -k av1 -encoder gpu -bm cbr -q ${toString bitrate} \
          -r 120 -replay-storage disk -restart-replay-on-save no \
          -sc ${replaySaved}/bin/replay-saved-${label} \
          -o "${replayDir}/.buffers/${label}"
      '';
    };

  primaryLaunch = mkReplayLaunch {
    label = "primary";
    fps = 60;
    bitrate = 6000;
    model = if isFern then "Dell S2716DG" else null;
  };
  leftLaunch = mkReplayLaunch {
    label = "left";
    fps = 30;
    bitrate = 2000;
    model = "BenQ GW2780";
  };
  rightLaunch = mkReplayLaunch {
    label = "right";
    fps = 30;
    bitrate = 2000;
    model = "DELL E2020H";
  };

  mkReplayService = label: launch: {
    partOf = [ "mango-session.target" ];
    after = [ "graphical-session.target" ];
    unitConfig.ConditionEnvironment = "WAYLAND_DISPLAY";
    serviceConfig = {
      ExecStartPre = "${pkgs.coreutils}/bin/install -d -m 0700 ${systemdReplayDir}/.buffers/${label}";
      ExecStart = "${launch}/bin/replay-buffer-${label}";
      KillSignal = "SIGINT";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  replayMode = pkgs.writeShellApplication {
    name = "replay-mode";
    runtimeInputs = [
      pkgs.libnotify
      pkgs.systemd
    ];
    text = ''
      set -euo pipefail
      trap '${refreshWaybar}' EXIT
      units=(${unitsShell})
      side_units=(${sideUnitsShell})
      mode="''${1:-}"

      case "$mode" in
        off)
          systemctl --user stop "''${units[@]}"
          message=Off
          ;;
        primary)
          systemctl --user start replay-buffer-primary.service
          ((''${#side_units[@]} == 0)) || systemctl --user stop "''${side_units[@]}"
          message=Primary
          ;;
        all)
          ((''${#side_units[@]} > 0)) || {
            notify-send --urgency=critical "Replay mode unavailable" "All-monitor mode is only available on Fern"
            exit 64
          }
          systemctl --user start "''${units[@]}"
          message=All
          ;;
        *)
          printf 'usage: replay-mode off|primary|all\n' >&2
          exit 64
          ;;
      esac

      notify-send --urgency=low "Replay mode" "$message"
    '';
  };

  replayModeMenu = pkgs.writeShellApplication {
    name = "replay-mode-menu";
    runtimeInputs = [
      replayMode
      pkgs.vicinae
    ];
    text = ''
      set -euo pipefail
      choices=(Off Primary)
      ${lib.optionalString isFern "choices+=(All)"}
      choice="$(printf '%s\n' "''${choices[@]}" |
        vicinae dmenu --navigation-title 'Replay mode' --placeholder 'Select capture mode')" || exit 0
      [[ -n "$choice" ]] || exit 0
      replay-mode "''${choice,,}"
    '';
  };

  replayStatus = pkgs.writeShellApplication {
    name = "replay-status";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
      pkgs.systemd
    ];
    text = ''
      set -euo pipefail
      primary=false
      left=false
      right=false
      systemctl --user --quiet is-active replay-buffer-primary.service && primary=true
      ${lib.optionalString isFern ''
        systemctl --user --quiet is-active replay-buffer-left.service && left=true
        systemctl --user --quiet is-active replay-buffer-right.service && right=true
      ''}

      if [[ "$primary" == false && "$left" == false && "$right" == false ]]; then
        mode=off; text='REC'
      elif [[ "$primary" == true && "$left" == false && "$right" == false ]]; then
        mode=primary; text='● REC'
      elif [[ "$primary" == true && "$left" == true && "$right" == true ]]; then
        mode=all; text='● REC ALL'
      else
        mode=degraded; text='! REC'
      fi

      size="$(du -sh "${replayDir}" 2>/dev/null | cut -f1 || printf 0)"
      tooltip="Replay: $mode ($size)"
      tooltip+=$'\nPrimary: '"$primary"
      ${lib.optionalString isFern ''
        tooltip+=$'\nLeft: '"$left"
        tooltip+=$'\nRight: '"$right"
      ''}
      tooltip+=$'\nLeft click: select mode\nRight click: save\nMiddle click: recent replays'
      jq -cn --arg text "$text" --arg tooltip "$tooltip" --arg class "$mode" \
        '{text: $text, tooltip: $tooltip, class: $class}'
    '';
  };

  replaySave = pkgs.writeShellApplication {
    name = "replay-save";
    runtimeInputs = [
      pkgs.libnotify
      pkgs.systemd
    ];
    text = ''
      set -euo pipefail
      units=(${unitsShell})
      active=()
      for unit in "''${units[@]}"; do
        if systemctl --user --quiet is-active "$unit"; then
          active+=("$unit")
        fi
      done
      ((''${#active[@]} > 0)) || {
        notify-send --urgency=critical "Replay unavailable" "Select Primary or All first"
        exit 1
      }
      for unit in "''${active[@]}"; do
        systemctl --user kill --kill-whom=main --signal=SIGUSR1 "$unit"
      done
      notify-send --urgency=low "Replay" "Saving ''${#active[@]} active buffer(s)"
    '';
  };

  replayRecent = pkgs.writeShellApplication {
    name = "replay-recent";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.findutils
      pkgs.gnused
      pkgs.libnotify
      pkgs.losslesscut-bin
      pkgs.python3
      pkgs.systemd
      pkgs.vicinae
      pkgs.wl-clipboard
      pkgs.xdg-utils
    ];
    text = ''
            set -euo pipefail
            install -d -m 0700 "${replayDir}"
            latest="$(find "${replayDir}" -maxdepth 1 -type f -name '*.mp4' -printf '%T@\t%p\n' |
              sort -nr | cut -f2- | sed -n '1p')"
            [[ -n "$latest" ]] || {
              notify-send --urgency=low "Recent replays" "No saved replays"
              exit 0
            }

            chooser="$(mktemp)"
            trap 'rm -f "$chooser"' EXIT
      ${lib.getExe richenLib.wrappers.kitty} --class replay-picker --title 'Recent replays' \
        -e ${lib.getExe' richenLib.wrappers.yazi "yazi"} --chooser-file "$chooser" "$latest" || exit 0
            file="$(sed -n '1p' "$chooser")"
            [[ -n "$file" ]] || exit 0
            root="$(realpath "${replayDir}")"
            file="$(realpath -- "$file")"
            [[ -f "$file" && "$file" == "$root/"* && "$file" == *.mp4 ]] || {
              notify-send --urgency=critical "Replay selection rejected" "Choose an MP4 from the replay folder"
              exit 1
            }

            action="$(printf '%s\n' 'Copy file' 'Copy path' 'Trim' 'Open location' 'Delete' |
              vicinae dmenu --placeholder "$(basename "$file")")" || exit 0
            case "$action" in
              'Copy file')
                uri="$(python3 - "$file" <<'PY'
      import pathlib, sys
      print(pathlib.Path(sys.argv[1]).resolve().as_uri())
      PY
                )"
                printf '%s\r\n' "$uri" | wl-copy --type text/uri-list
                ;;
              'Copy path') printf %s "$file" | wl-copy --type text/plain ;;
              Trim)
                unit="losslesscut-$(date +%s%N)"
                systemd-run --user --collect --unit="$unit" \
                  ${lib.getExe pkgs.losslesscut-bin} --no-sandbox "$file" >/dev/null
                ;;
              'Open location') xdg-open "$(dirname "$file")" ;;
              Delete)
                choice="$(printf '%s\n' Cancel Delete | vicinae dmenu \
                  --placeholder "Delete $(basename "$file")?")" || exit 0
                [[ "$choice" == Delete ]] && rm -- "$file"
                ;;
            esac
    '';
  };

  mkDesktop =
    {
      name,
      desktopName,
      exec,
      icon,
    }:
    pkgs.makeDesktopItem {
      inherit
        name
        desktopName
        exec
        icon
        ;
      categories = [
        "AudioVideo"
        "Utility"
      ];
    };
  saveDesktop = mkDesktop {
    name = "replay-save";
    desktopName = "Replay - Save active buffers";
    exec = "${replaySave}/bin/replay-save";
    icon = "media-record";
  };
  recentDesktop = mkDesktop {
    name = "replay-recent";
    desktopName = "Replay - Recent actions";
    exec = "${replayRecent}/bin/replay-recent";
    icon = "video-x-generic";
  };
  modeDesktop = mkDesktop {
    name = "replay-mode";
    desktopName = "Replay - Select capture mode";
    exec = "${replayModeMenu}/bin/replay-mode-menu";
    icon = "media-record";
  };
in
{
  environment.systemPackages = [
    pkgs.losslesscut-bin
    replayMode
    replayModeMenu
    replayStatus
    replaySave
    replayRecent
    saveDesktop
    recentDesktop
    modeDesktop
  ];

  systemd.user.services = {
    replay-buffer-primary = mkReplayService "primary" primaryLaunch;
  }
  // lib.optionalAttrs isFern {
    replay-buffer-left = mkReplayService "left" leftLaunch;
    replay-buffer-right = mkReplayService "right" rightLaunch;
  };

  systemd.user.tmpfiles.rules = [
    "d ${systemdReplayDir} 0700 - - -"
    "d ${systemdReplayDir}/.buffers 0700 - - -"
    "e ${systemdReplayDir} 0700 - - 14d"
  ];
}
