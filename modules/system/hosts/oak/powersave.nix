{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.oak.powersave;
in
{
  options.modules.oak.powersave = {
    enable = lib.mkEnableOption "Enable power saving configuration for ASUS Vivobook Pro 16";
  };

  config = lib.mkIf cfg.enable {
    # Add required packages
    environment.systemPackages = with pkgs; [
      tlp
      powertop
      thermald
      auto-cpufreq
    ];

    # Enable power management
    powerManagement = {
      enable = true;
      cpuFreqGovernor = lib.mkDefault "powersave";
      powertop.enable = true;
    };

    # Enable TLP for advanced power management
    services.tlp = {
      enable = true;
      settings = {
        # CPU settings
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        CPU_SCALING_MIN_FREQ_ON_BAT = 0;
        CPU_SCALING_MAX_FREQ_ON_BAT = 0;
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

        # PCIe power management
        PCIE_ASPM_ON_BAT = "powersupersave";

        # SATA power management
        SATA_LINKPWR_ON_BAT = "min_power";

        # WiFi power saving
        WIFI_PWR_ON_BAT = "on";

        # Audio power saving
        SOUND_POWER_SAVE_ON_BAT = 1;

        # USB autosuspend
        USB_AUTOSUSPEND = 1;
        USB_BLACKLIST_BTUSB = 1;

        # Disk power management
        DISK_DEVICES = "nvme0n1 sda";
        DISK_APM_LEVEL_ON_BAT = "128 128";
        DISK_SPINDOWN_TIMEOUT_ON_BAT = "0 0";

        # Runtime power management
        RUNTIME_PM_ON_BAT = "auto";

        # Battery charge thresholds
        START_CHARGE_THRESH_BAT0 = 75;
        STOP_CHARGE_THRESH_BAT0 = 80;
      };
    };

    # Enable thermald for thermal management
    services.thermald.enable = true;

    # Enable auto-cpufreq for dynamic CPU frequency scaling
    services.auto-cpufreq.enable = true;
    services.auto-cpufreq.settings = {
      battery = {
        governor = "powersave";
        turbo = "never";
      };
      charger = {
        governor = "performance";
        turbo = "auto";
      };
    };

    # Enable systemd power management
    systemd.targets = {
      "power-save" = {
        description = "Power Save Mode";
        requires = [ "multi-user.target" ];
        after = [ "multi-user.target" ];
        unitConfig = {
          AllowIsolate = "yes";
        };
      };
    };

    # Add power saving kernel parameters
    boot.kernelParams = [
      "mem_sleep_default=deep"
      "processor.max_cstate=5"
      "intel_idle.max_cstate=4"
      "i915.enable_rc6=1"
      "i915.enable_fbc=1"
      "i915.lvds_downclock=1"
    ];
  };
}
