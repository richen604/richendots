{ pkgs, ... }:

let
  nixpull = "/run/current-system/sw/bin/nixpull";

  nixpullLauncher = pkgs.writeShellApplication {
    name = "nixpull-launcher";
    text = ''
      set -euo pipefail

      command=''${1:-}
      if [ -z "$command" ]; then
        printf 'usage: nixpull-launcher <status|fetch|apply|pull>\n' >&2
        exit 2
      fi

      if [ ! -x ${nixpull} ]; then
        printf 'nixpull is not installed on this host\n'
        printf '\npress enter to close...'
        read -r _
        exit 1
      fi

      printf 'nixpull - %s\n\n' "$command"
      set +e
      case "$command" in
        status)
          ${nixpull} status
          ;;
        fetch)
          ${nixpull} fetch
          ;;
        apply)
          ${nixpull} activate
          ;;
        pull)
          ${nixpull} pull
          ;;
        *)
          printf 'unknown nixpull command: %s\n' "$command" >&2
          rc=2
          ;;
      esac
      rc=''${rc:-$?}
      set -e

      if [ "$rc" -ne 0 ]; then
        printf '\nexited with status %s\n' "$rc"
      fi

      printf '\npress enter to close...'
      read -r _
      exit "$rc"
    '';
  };

  mkDesktopItem =
    command:
    pkgs.makeDesktopItem {
      name = "nixpull-${command}";
      desktopName = "nixpull - ${command}";
      genericName = "nixos updates";
      comment = "run nixpull ${command}";
      exec = "kitty --class nixpull --title nixpull-${command} -e ${pkgs.lib.getExe nixpullLauncher} ${command}";
      icon = "software-update-available";
      terminal = false;
      categories = [
        "System"
        "Settings"
      ];
    };

  desktopItems = map mkDesktopItem [
    "status"
    "fetch"
    "apply"
    "pull"
  ];
in
pkgs.symlinkJoin {
  name = "nixpull-launcher";
  paths = [ nixpullLauncher ] ++ desktopItems;
}
