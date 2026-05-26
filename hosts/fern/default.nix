{
  pkgs,
  ...
}:
let
  sunshineSetResolution = pkgs.writeShellScriptBin "sunshine-set-resolution" ''
    MAIN_DP=$(${pkgs.wlr-randr}/bin/wlr-randr --json | ${pkgs.jq}/bin/jq -r '.[] | select(.description | contains("Dell S2716DG")) | .name')
    ${pkgs.wlr-randr}/bin/wlr-randr --output $MAIN_DP --custom-mode "''${SUNSHINE_CLIENT_WIDTH}x''${SUNSHINE_CLIENT_HEIGHT}@''${SUNSHINE_CLIENT_FPS}Hz"
  '';
in
{
  imports = [
    ./hardware-configuration.nix
    ./drivers.nix
  ];

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "/home/richen/newdev/richendots";
  };

  networking.interfaces.enp7s0.wakeOnLan.enable = true;

  # TODO: make swap module for fern
  swapDevices = [
    {
      device = "/swapfile";
      size = 96 * 1024;
    }
  ];
  boot.resumeDevice = "/dev/disk/by-uuid/f3573fb1-5c09-4c7a-b3d4-ef0e73ad547f";
  boot.kernelParams = [
    "resume_offset=67471360"

    # gaming performance
    "mitigations=off"
  ];

  hardware.cpu.intel.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;

  # CPU scaling settings
  powerManagement = {
    enable = true;
    cpuFreqGovernor = "performance";
    powertop.enable = false;
  };

  # todo: fern: review below kernel sysctls
  boot.kernel.sysctl = {
    "vm.swappiness" = 1; # Minimize swap usage for gaming
    "vm.overcommit_memory" = 2; # Prevent memory overcommit
    "vm.dirty_ratio" = 5; # Better memory management
    "vm.dirty_background_ratio" = 2; # Background writeback threshold
  };

  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
    applications = {
      apps = [
        {
          name = "Desktop";
          prep-cmd = [
            {
              do = "${pkgs.mangowc}/bin/mmsg -d disable_monitor,monitor_model:BenQ GW2780";
              undo = "${pkgs.mangowc}/bin/mmsg -d enable_monitor,monitor_model:BenQ GW2780";
            }
            {
              do = "${pkgs.mangowc}/bin/mmsg -d disable_monitor,monitor_model:DELL E2020H";
              undo = "${pkgs.mangowc}/bin/mmsg -d enable_monitor,monitor_model:DELL E2020H";
            }
            {
              do = "${sunshineSetResolution}/bin/sunshine-set-resolution";
              undo = ''
                MAIN_DP=$(${pkgs.wlr-randr}/bin/wlr-randr --json | ${pkgs.jq}/bin/jq -r '.[] | select(.description | contains("Dell S2716DG")) | .name')
                ${pkgs.wlr-randr}/bin/wlr-randr --output $MAIN_DP --off && ${pkgs.wlr-randr}/bin/wlr-randr --output $MAIN_DP --on
              '';
            }
            {
              do = "${pkgs.mangowc}/bin/mmsg -d reload_config";
            }
          ];
          exclude-global-prep-cmd = "false";
          auto-detach = "true";
        }
        {
          name = "Steam Big Picture";
          prep-cmd = [
            {
              do = "${pkgs.mangowc}/bin/mmsg -d disable_monitor,monitor_model:BenQ GW2780";
              undo = "${pkgs.mangowc}/bin/mmsg -d enable_monitor,monitor_model:BenQ GW2780";
            }
            {
              do = "${pkgs.mangowc}/bin/mmsg -d disable_monitor,monitor_model:DELL E2020H";
              undo = "${pkgs.mangowc}/bin/mmsg -d enable_monitor,monitor_model:DELL E2020H";
            }
            {
              do = "${sunshineSetResolution}/bin/sunshine-set-resolution";
              undo = ''
                MAIN_DP=$(${pkgs.wlr-randr}/bin/wlr-randr --json | ${pkgs.jq}/bin/jq -r '.[] | select(.description | contains("Dell S2716DG")) | .name')
                ${pkgs.wlr-randr}/bin/wlr-randr --output $MAIN_DP --off && ${pkgs.wlr-randr}/bin/wlr-randr --output $MAIN_DP --on
              '';
            }
            {
              do = "${pkgs.mangowc}/bin/mmsg -d reload_config";
            }
            {
              # launch steam in big picture mode
              do = "${pkgs.steam}/bin/steam steam://open/bigpicture";
            }
          ];
          exclude-global-prep-cmd = "false";
          auto-detach = "true";
        }
      ];
    };
    settings = {
      capture = "kms";
    };
  };

  programs.gamemode = {
    enable = true;
  };
  users.users.richen.extraGroups = [ "gamemode" ];

  system.stateVersion = pkgs.lib.mkDefault "26.05";
}
