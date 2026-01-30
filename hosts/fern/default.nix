{
  config,
  inputs,
  pkgs,
  richenLib,
  ...
}:
{
  imports = [
    inputs.hydenix.inputs.home-manager.nixosModules.home-manager
    inputs.hydenix.nixosModules.default
    ./hardware-configuration.nix
    ./vfio
    ./drivers.nix
  ];

  networking.hostName = "fern";

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs;
      osConfig = config;
    };
    users."richen" =
      { config, ... }:
      {
        imports = [
          inputs.hydenix.homeModules.default
          ../../modules/hm/users/richen
        ];

        desktops.hydenix = {
          enable = true;
          hostname = "fern";
        };

        home.stateVersion = "25.05";
        modules = {
          common = {
            git.enable = true;
            dev.enable = true;
            obs.enable = true;
            games.enable = true;
            zsh.enable = true;
          };
          # TODO: make obsidian.nix work on any host
          obsidian.enable = true;
        };
      };
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "/home/richen/newdev/richendots";
  };
  # for nh.clean
  nix.gc.automatic = pkgs.lib.mkForce false;
  # for spotify
  services.flatpak.enable = true;
  environment.systemPackages = [
    pkgs.spicetify-cli
    richenLib.wrappers.firefox
    richenLib.wrappers.keepassxc
    pkgs.mangohud
    pkgs.gamescope
  ];

  hydenix = {
    enable = true;
    hostname = "fern";
    timezone = "America/Vancouver";
    locale = "en_CA.UTF-8";
  };

  users.users.richen = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
    ];
  };

  # FONTS --------------------------------------------------------------

  environment.etc."gtk-3.0/gtk.css".text = ''
    label, entry, textview, button {
      font-weight: 600;
    }
  '';

  environment.etc."gtk-4.0/gtk.css".text = ''
    label, entry, textview, button {
      font-weight: 600;
    }
  '';

  fonts = {
    fontDir.enable = true;
    enableDefaultPackages = true;
    packages = with pkgs; [
      nerd-fonts.gohufont
      terminus_font
    ];
    fontconfig = {
      enable = true;
      localConf = ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
        <fontconfig>
          <match target="font">
            <test name="family" compare="contains">
              <string>Gohu</string>
            </test>
            <edit name="embolden" mode="assign">
              <bool>true</bool>
            </edit>
          </match>
        </fontconfig>
      '';
      defaultFonts = {
        monospace = [ "GohuFont uni14 Nerd Font Propo" ];
        sansSerif = [ "GohuFont uni14 Nerd Font Propo" ];
        serif = [ "GohuFont uni14 Nerd Font Propo" ];
      };
    };
  };

  programs = {
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      protontricks.enable = true;
    };
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

    # TODO: this and below are for gaming performance
    "mitigations=off" # Small performance boost, zen kernel handles this well
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

  hydenix.boot.enable = false;

  boot = {
    plymouth.enable = true;
    kernelPackages = pkgs.lib.mkForce pkgs.linuxPackages_6_12;
    loader.systemd-boot.enable = pkgs.lib.mkForce false;
    loader = {
      efi = {
        canTouchEfiVariables = true;
      };
      grub = {
        enable = true;
        device = "nodev";
        useOSProber = true;
        efiSupport = true;
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
  };

  system.stateVersion = pkgs.lib.mkDefault "26.05";
}
