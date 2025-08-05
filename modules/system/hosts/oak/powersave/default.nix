{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.oak.powersave;

  # Import scripts as derivations
  power-benchmark = pkgs.writeShellScript "power-benchmark" (builtins.readFile ./power-benchmark.sh);
  power-tuning = pkgs.writeShellScript "power-tuning" (builtins.readFile ./power-tuning.sh);

  # Create a package that includes both scripts
  power-tools = pkgs.writeShellScriptBin "power-tools" ''
    case "$1" in
      benchmark)
        shift
        exec ${power-benchmark} "$@"
        ;;
      tune)
        shift
        exec ${power-tuning} "$@"
        ;;
      *)
        echo "Power Tools for ASUS Vivobook Pro 16"
        echo "Usage: power-tools <command> [options]"
        echo ""
        echo "Commands:"
        echo "  benchmark [duration]    Run power consumption benchmarks"
        echo "  tune <command>          Tune power settings"
        echo ""
        echo "Examples:"
        echo "  power-tools benchmark 60"
        echo "  power-tools tune profile max-powersave"
        echo "  power-tools tune status"
        echo ""
        echo "For detailed help:"
        echo "  power-tools benchmark --help"
        echo "  power-tools tune help"
        ;;
    esac
  '';
in
{
  options.modules.oak.powersave = {
    enable = lib.mkEnableOption "Enable power saving configuration for ASUS Vivobook Pro 16";

    useAutoFreq = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Use auto-cpufreq instead of manual governor settings";
    };

    enableBenchmarkTools = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install power benchmarking and tuning tools";
    };
  };

  config = lib.mkIf cfg.enable {
    # Add required packages (removed TLP, keeping auto-cpufreq)
    environment.systemPackages =
      with pkgs;
      [
        powertop
        thermald
        auto-cpufreq
      ]
      ++ lib.optionals cfg.enableBenchmarkTools [
        power-tools
        bc # Required for calculations in scripts
        iw # Required for WiFi power management
      ];

    # Create symlinks to individual scripts for direct access
    environment.etc = lib.mkIf cfg.enableBenchmarkTools {
      "power-scripts/power-benchmark.sh" = {
        source = power-benchmark;
        mode = "0755";
      };
      "power-scripts/power-tuning.sh" = {
        source = power-tuning;
        mode = "0755";
      };
    };

    # Enable power management
    powerManagement = {
      enable = true;
      # Let auto-cpufreq handle governor selection if enabled
      cpuFreqGovernor = lib.mkIf (!cfg.useAutoFreq) (lib.mkDefault "powersave");
      powertop.enable = true;
    };

    # Enable thermald for thermal management
    services.thermald.enable = true;

    # Enable auto-cpufreq for dynamic CPU frequency scaling
    services.auto-cpufreq = lib.mkIf cfg.useAutoFreq {
      enable = true;
      settings = {
        battery = {
          governor = "powersave";
          turbo = "never";
          # Commented out for benchmarking - can be adjusted based on results
          # scaling_min_freq = 800000;  # 800 MHz
          # scaling_max_freq = 2000000; # 2 GHz
        };
        charger = {
          governor = "performance";
          turbo = "auto";
          # Commented out for benchmarkings
          # scaling_min_freq = 800000;  # 800 MHz
          # scaling_max_freq = 3500000; # 3.5 GHz
        };
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

    # Power saving kernel parameters
    # Commented some for benchmarking - adjust based on testing results
    boot.kernelParams = [
      "mem_sleep_default=deep"
      # "processor.max_cstate=5"      # Test different C-states
      # "intel_idle.max_cstate=4"     # May impact latency vs power
      "i915.enable_rc6=1" # Intel GPU power saving
      "i915.enable_fbc=1" # Frame buffer compression
      # "i915.lvds_downclock=1"       # Test if this helps or hurts
      # Additional kernel parameters to test:
      # "pcie_aspm.policy=powersupersave"  # PCIe power management
      # "intel_pstate=passive"             # Use acpi-cpufreq instead of intel_pstate
    ];
  };
}
