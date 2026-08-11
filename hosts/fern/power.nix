{ pkgs, ... }:
{
  powerManagement = {
    enable = true;
    cpuFreqGovernor = "powersave";
    powertop.enable = false;
  };

  systemd.services.intel-pstate-policy = {
    description = "Apply Fern Intel P-state power policy";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-modules-load.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      echo 95 > /sys/devices/system/cpu/intel_pstate/max_perf_pct
      for policy in /sys/devices/system/cpu/cpufreq/policy*; do
        echo balance_power > "$policy/energy_performance_preference"
      done
    '';
    path = [ pkgs.coreutils ];
  };
}
