{ pkgs, ... }:
{
  imports = [
    ./autologin.nix
    ./boot.nix
    ./linux-cachyos.nix
    ./steam.nix
    ./nix.nix
  ];

  # TODO: move this somewhere?
  # For dolphin udisks2 permission for click mounting disks
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id.indexOf("org.freedesktop.udisks2.") == 0 && 
          subject.isInGroup("users")) {
          return polkit.Result.YES;
      }
    });
  '';

  # TODO: fix this later
  environment.systemPackages = [
    pkgs.glxinfo
    pkgs.gamescope
    pkgs.libva-utils
    pkgs.cudaPackages.cuda_cudart
    pkgs.cudaPackages.cuda_nvcc
    pkgs.grub2
    pkgs.virglrenderer
    pkgs.fzf
    # TODO: fix reboot-to and move this somewhere else
    (pkgs.writeScriptBin "reboot-to" ''
      #!${pkgs.bash}/bin/bash

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

    pkgs.userPkgs.spotube
  ];

}
