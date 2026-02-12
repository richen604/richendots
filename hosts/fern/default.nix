{
  pkgs,
  ...
}:
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
  # for nh.clean
  nix.gc.automatic = pkgs.lib.mkForce false;

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

  system.stateVersion = pkgs.lib.mkDefault "26.05";
}
