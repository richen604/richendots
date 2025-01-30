{
  config,
  userConfig,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./modules/system/vfio/vfio.nix
    ./modules/system/plex.nix
    ./modules/system/wol.nix
    ./modules/system/steam.nix
    ./modules/system/sunshine.nix
    ./modules/system/autologin.nix
    ./modules/system/linux-cachyos.nix
    ./modules/system/gamescope.nix

    inputs.nixos-hardware.nixosModules.common-cpu-intel
    #inputs.nixos-hardware.nixosModules.common-gpu-amd
  ];

  modules = {
    wol = {
      enable = true;
      interface = "enp7s0";
    };
    sunshine.enable = true;
    autologin.enable = true;
    gamescope-nvidia.enable = true;
  };

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    nvidia = pkgs.lib.mkForce {
      modesetting.enable = true;
      powerManagement.enable = false;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      prime = {
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
        amdgpuBusId = "PCI:3:0:0";
        nvidiaBusId = "PCI:8:0:0";
      };
    };

    amdgpu = {
      initrd.enable = true;
    };
  };

  boot = {
    plymouth.enable = true;
    loader.systemd-boot.enable = pkgs.lib.mkForce false;
    loader = {
      efi = {
        canTouchEfiVariables = true;
      };
      grub = {
        enable = true;
        devices = [ "nodev" ];
        efiSupport = true;
        useOSProber = true;
        configurationLimit = 10;
        extraEntries = ''
          menuentry "UEFI Firmware Settings" {
            fwsetup
          }
        '';
      };
    };
    kernelModules = [
      "v4l2loopback"
    ];
    extraModprobeConfig = ''
      options v4l2loopback devices=2 video_nr=1,2 card_label="OBS Cam, Virt Cam" exclusive_caps=1
    '';
    resumeDevice = "/dev/disk/by-uuid/92615496-7f61-4930-8fe0-48ac125f02e8";
  };

  environment.systemPackages = with pkgs; [
    glxinfo
    gamescope
    libva-utils
    cudaPackages.cuda_cudart
    cudaPackages.cuda_nvcc
    grub2
    virglrenderer
    fzf
    (writeScriptBin "reboot-to" ''
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

    nodejs_20
    nodePackages.pnpm
    pnpm

    cpufrequtils
  ];

  # Add capability settings for gamescope
  security.wrappers.gamescope = {
    owner = "root";
    group = "root";
    capabilities = "cap_sys_nice+ep";
    source = "${pkgs.gamescope}/bin/gamescope";
  };

  services = {
    xserver = {
      enable = true;
      videoDrivers = [
        "amdgpu"
        "nvidia"
      ];
    };
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
        MaxAuthTries = 3;
      };
    };
  };
  networking.firewall.allowedTCPPorts = [ 22 ];

  users.users.${userConfig.username}.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICLEXtZYHT5O3cWgfF2FHEjXHa/FPGGqOpBAAe7LeDvW"
  ];

  # Allow users in the "users" group to mount drives
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id.indexOf("org.freedesktop.udisks2.") == 0 && 
          subject.isInGroup("users")) {
          return polkit.Result.YES;
      }
    });
  '';

  # nix = {

  #   gc = {
  #     automatic = true;
  #     dates = "weekly";
  #     options = "--delete-older-than 7d";
  #     persistent = true;
  #   };
  #   settings = {
  #     auto-optimise-store = true;
  #     # Prevents accidentally deleting derivations that are in use
  #     keep-outputs = true;
  #     keep-derivations = true;
  #   };
  # };

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      # Add common dynamic libraries that programs might need
      stdenv.cc.cc
      openssl
      curl
      glib
      util-linux
      glibc
      icu
      libunwind
      libuuid
      zlib
      # Add any other libraries you might need

      # Node.js dependencies
      nodejs_20
      nodePackages.pnpm
      # Common runtime dependencies
      stdenv.cc.cc
      openssl
      zlib
      pnpm
    ];
  };

}
