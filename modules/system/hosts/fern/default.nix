{ inputs, ... }:
{
  imports = [
    inputs.richendots-private.nixosModules.fern
    ../../common
    ./drivers.nix
    ./sunshine.nix
    ./vfio
    ./wol.nix
  ];

  modules = {
    openrgb.enable = true;
    autologin.enable = false;
    boot.enable = true;
    steam.enable = true;
    # fern specific modules
    fern = {
      wol = {
        enable = true;
        interface = "enp7s0";
      };
      drivers.enable = true;
      sunshine.enable = true;
      vfio.enable = true;
    };

  };

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

  # CPU microcode updates (important for performance and security)
  hardware.cpu.intel.updateMicrocode = true; # or hardware.cpu.amd.updateMicrocode
  hardware.enableRedistributableFirmware = true;

  # CPU scaling settings
  powerManagement = {
    enable = true;
    cpuFreqGovernor = "performance";
    # Set minimum CPU frequency (prevents deep sleep states that cause latency)
    cpufreq.min = 2000000; # 2GHz minimum (adjust for your CPU)
    # Disable CPU power saving features that can cause stutters
    powertop.enable = false;
  };

  # Simple gaming-friendly tweaks
  boot.kernel.sysctl = {
    "vm.swappiness" = 1; # Minimize swap usage for gaming
  };
}
