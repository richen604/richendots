{
  pkgs,
  lib,
  config,
  ...
}:
let
  sunshineSetResolution = pkgs.writeShellScriptBin "sunshine-set-resolution" ''
    ${pkgs.wlr-randr}/bin/wlr-randr --output DP-4 --custom-mode "''${SUNSHINE_CLIENT_WIDTH}x''${SUNSHINE_CLIENT_HEIGHT}@''${SUNSHINE_CLIENT_FPS}Hz"
  '';

  sunshineStartGamescope = pkgs.writeShellScriptBin "sunshine-start-gamescope" ''
    ${pkgs.gamescope}/bin/gamescope \
      --output-width "''${SUNSHINE_CLIENT_WIDTH}" \
      --output-height "''${SUNSHINE_CLIENT_HEIGHT}" \
      --nested-refresh "''${SUNSHINE_CLIENT_FPS}" \
      --fullscreen \
      --expose-wayland \
      --backend=sdl \
      --force-grab-cursor \
      --immediate-flips \
      --rt &
  '';
in
{
  imports = [
    ./hardware-configuration.nix
    ./vfio
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

  # nixpull client configuration
  services.nixpull = {
    enable = true;
    mode = "client";
    checkInterval = "hourly";
    enableNotifications = true;
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
              do = "${pkgs.mangowc}/bin/mmsg -d disable_monitor,DP-5";
              undo = "${pkgs.mangowc}/bin/mmsg -d enable_monitor,DP-5";
            }
            {
              do = "${pkgs.mangowc}/bin/mmsg -d disable_monitor,DP-6";
              undo = "${pkgs.mangowc}/bin/mmsg -d enable_monitor,DP-6";
            }
            {
              do = "${sunshineSetResolution}/bin/sunshine-set-resolution";
              undo = "${pkgs.wlr-randr}/bin/wlr-randr --output DP-4 --off && ${pkgs.wlr-randr}/bin/wlr-randr --output DP-4 --on";
            }
            {
              do = "${sunshineStartGamescope}/bin/sunshine-start-gamescope";
              undo = "pkill gamescope";
            }
            {
              do = "${pkgs.mangowc}/bin/mmsg -d reload_config";
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
    settings = {
      general = {
        defaultgov = "schedutil";
        desiredgov = "performance";
        renice = 10;
        softrealtime = "auto";
      };
      cpu.pin_cores = "yes";
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 1;
        amd_performance_level = "high";
      };
    };
  };
  users.users.richen.extraGroups = [ "gamemode" ];

  programs.gamescope = {
    # env = {
    #   __NV_PRIME_RENDER_OFFLOAD = "1";
    #   __NV_PRIME_RENDER_OFFLOAD_PROVIDER = "NVIDIA-G0";
    #   __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    # };
    enable = true;
    args = [
      "-W 2560"
      "-H 1440"
      "-w 2560"
      "-h 1440"
      "-r 144"
      "-b"
      # "--backend=sdl"
      # "--immediate-flips" # may cause tearing
      "--rt" # realtime scheduling
    ];
  };

  system.stateVersion = pkgs.lib.mkDefault "26.05";
}
