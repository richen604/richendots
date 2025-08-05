#!/usr/bin/env bash

# Power Tuning Script for ASUS Vivobook Pro 16
# This script allows runtime adjustment of power settings for testing

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETTINGS_FILE="/tmp/power-settings-backup.conf"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

backup_current_settings() {
    log "Backing up current settings to $SETTINGS_FILE"

    cat > "$SETTINGS_FILE" << EOF
# Power settings backup - $(date)
cpu_governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "unknown")
EOF

    # Backup PCIe ASPM if available
    if [[ -f /sys/module/pcie_aspm/parameters/policy ]]; then
        echo "pcie_aspm=$(cat /sys/module/pcie_aspm/parameters/policy)" >> "$SETTINGS_FILE"
    fi

    # Backup runtime PM settings for some common devices
    for device in /sys/bus/pci/devices/*/power/control; do
        if [[ -f "$device" ]]; then
            local device_path=$(dirname "$device")
            local device_id=$(basename "$(dirname "$device_path")")
            echo "runtime_pm_${device_id}=$(cat "$device")" >> "$SETTINGS_FILE"
        fi
    done
}

restore_settings() {
    if [[ ! -f "$SETTINGS_FILE" ]]; then
        log "No backup file found at $SETTINGS_FILE"
        return 1
    fi

    log "Restoring settings from $SETTINGS_FILE"

    # shellcheck source=/dev/null
    source "$SETTINGS_FILE"

    # Restore CPU governor
    if [[ -n "${cpu_governor:-}" ]]; then
        set_cpu_governor "$cpu_governor"
    fi

    log "Settings restored"
}

set_cpu_governor() {
    local governor=$1
    local available_governors
    available_governors=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null || echo "")

    if [[ ! "$available_governors" =~ $governor ]]; then
        log "Error: Governor '$governor' not available. Available: $available_governors"
        return 1
    fi

    log "Setting CPU governor to: $governor"
    for cpu_dir in /sys/devices/system/cpu/cpu*/cpufreq/; do
        if [[ -f "${cpu_dir}scaling_governor" ]]; then
            echo "$governor" > "${cpu_dir}scaling_governor"
        fi
    done
}

set_cpu_frequency_limits() {
    local min_freq=${1:-}
    local max_freq=${2:-}

    if [[ -n "$min_freq" ]]; then
        log "Setting minimum CPU frequency to: ${min_freq}MHz"
        for cpu_dir in /sys/devices/system/cpu/cpu*/cpufreq/; do
            if [[ -f "${cpu_dir}scaling_min_freq" ]]; then
                echo $((min_freq * 1000)) > "${cpu_dir}scaling_min_freq"
            fi
        done
    fi

    if [[ -n "$max_freq" ]]; then
        log "Setting maximum CPU frequency to: ${max_freq}MHz"
        for cpu_dir in /sys/devices/system/cpu/cpu*/cpufreq/; do
            if [[ -f "${cpu_dir}scaling_max_freq" ]]; then
                echo $((max_freq * 1000)) > "${cpu_dir}scaling_max_freq"
            fi
        done
    fi
}

set_pcie_aspm() {
    local policy=$1
    local available_policies

    if [[ ! -f /sys/module/pcie_aspm/parameters/policy ]]; then
        log "PCIe ASPM not available"
        return 1
    fi

    available_policies=$(cat /sys/module/pcie_aspm/parameters/policy | tr -d '[]')

    if [[ ! "$available_policies" =~ $policy ]]; then
        log "Error: PCIe ASPM policy '$policy' not available. Available: $available_policies"
        return 1
    fi

    log "Setting PCIe ASPM policy to: $policy"
    echo "$policy" > /sys/module/pcie_aspm/parameters/policy
}

set_runtime_pm() {
    local mode=$1  # "auto" or "on"

    log "Setting runtime power management to: $mode"

    # Apply to PCI devices
    for device in /sys/bus/pci/devices/*/power/control; do
        if [[ -f "$device" ]]; then
            echo "$mode" > "$device"
        fi
    done

    # Apply to USB devices (be careful with input devices)
    for device in /sys/bus/usb/devices/*/power/control; do
        if [[ -f "$device" ]]; then
            local device_path=$(dirname "$device")
            local product_file="${device_path}/product"

            # Skip input devices like keyboards and mice
            if [[ -f "$product_file" ]]; then
                local product=$(cat "$product_file" 2>/dev/null || echo "")
                if [[ ! "$product" =~ (Keyboard|Mouse|HID) ]]; then
                    echo "$mode" > "$device"
                fi
            else
                echo "$mode" > "$device"
            fi
        fi
    done
}

set_wifi_power_save() {
    local mode=$1  # "on" or "off"

    log "Setting WiFi power save to: $mode"

    # Find wireless interfaces
    for iface in /sys/class/net/*/wireless; do
        if [[ -d "$iface" ]]; then
            local interface=$(basename "$(dirname "$iface")")
            if command -v iw &> /dev/null; then
                iw dev "$interface" set power_save "$mode" 2>/dev/null || log "Could not set power save for $interface"
            fi
        fi
    done
}

apply_power_profile() {
    local profile=$1

    backup_current_settings

    case "$profile" in
        "max-performance")
            log "Applying maximum performance profile"
            set_cpu_governor "performance"
            set_pcie_aspm "performance" 2>/dev/null || true
            set_runtime_pm "on"
            set_wifi_power_save "off"
            ;;
        "balanced")
            log "Applying balanced profile"
            set_cpu_governor "schedutil"
            set_pcie_aspm "default" 2>/dev/null || true
            set_runtime_pm "auto"
            set_wifi_power_save "on"
            ;;
        "max-powersave")
            log "Applying maximum power save profile"
            set_cpu_governor "powersave"
            set_pcie_aspm "powersupersave" 2>/dev/null || true
            set_runtime_pm "auto"
            set_wifi_power_save "on"
            ;;
        "custom-powersave")
            log "Applying custom power save profile"
            set_cpu_governor "powersave"
            set_cpu_frequency_limits "" "2000"  # Limit max frequency to 2GHz
            set_pcie_aspm "powersupersave" 2>/dev/null || true
            set_runtime_pm "auto"
            set_wifi_power_save "on"
            ;;
        *)
            log "Unknown profile: $profile"
            log "Available profiles: max-performance, balanced, max-powersave, custom-powersave"
            return 1
            ;;
    esac

    log "Profile '$profile' applied successfully"
}

run_benchmark() {
    local duration=${1:-30}

    if [[ -f "$SCRIPT_DIR/power-benchmark.sh" ]]; then
        log "Running benchmark for $duration seconds..."
        "$SCRIPT_DIR/power-benchmark.sh" "$duration"
    else
        log "Benchmark script not found at $SCRIPT_DIR/power-benchmark.sh"
    fi
}

show_current_settings() {
    log "=== Current Power Settings ==="
    log "CPU Governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo 'unknown')"

    # Show frequency limits
    local min_freq max_freq
    min_freq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq 2>/dev/null || echo 0)
    max_freq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq 2>/dev/null || echo 0)
    log "CPU Frequency Range: $((min_freq / 1000))MHz - $((max_freq / 1000))MHz"

    # Show PCIe ASPM
    if [[ -f /sys/module/pcie_aspm/parameters/policy ]]; then
        log "PCIe ASPM Policy: $(cat /sys/module/pcie_aspm/parameters/policy)"
    fi

    # Show runtime PM status for a few devices
    local runtime_pm_count=0
    for device in /sys/bus/pci/devices/*/power/control; do
        if [[ -f "$device" && $runtime_pm_count -lt 3 ]]; then
            local device_id=$(basename "$(dirname "$(dirname "$device")")")
            log "Runtime PM ($device_id): $(cat "$device")"
            runtime_pm_count=$((runtime_pm_count + 1))
        fi
    done
}

show_help() {
    cat << EOF
Power Tuning Script

Usage: $0 [command] [options]

Commands:
    profile <name>           Apply a power profile
    governor <name>          Set CPU governor
    freq-limits <min> <max>  Set CPU frequency limits (MHz)
    pcie-aspm <policy>       Set PCIe ASPM policy
    runtime-pm <mode>        Set runtime PM (auto/on)
    wifi-powersave <mode>    Set WiFi power save (on/off)
    benchmark [duration]     Run power benchmark
    backup                   Backup current settings
    restore                  Restore backed up settings
    status                   Show current settings
    help                     Show this help

Power Profiles:
    max-performance          Maximum performance, highest power
    balanced                 Balanced performance and power
    max-powersave           Maximum power savings
    custom-powersave        Custom power save with frequency limits

Examples:
    $0 profile max-powersave
    $0 governor powersave
    $0 freq-limits 800 2000
    $0 benchmark 60
    $0 restore

Note: Most commands require root privileges
EOF
}

main() {
    if [[ $EUID -ne 0 ]]; then
        log "Warning: Most power tuning operations require root privileges"
    fi

    case "${1:-help}" in
        "profile")
            apply_power_profile "${2:-balanced}"
            ;;
        "governor")
            set_cpu_governor "${2:-}"
            ;;
        "freq-limits")
            set_cpu_frequency_limits "${2:-}" "${3:-}"
            ;;
        "pcie-aspm")
            set_pcie_aspm "${2:-}"
            ;;
        "runtime-pm")
            set_runtime_pm "${2:-auto}"
            ;;
        "wifi-powersave")
            set_wifi_power_save "${2:-on}"
            ;;
        "benchmark")
            run_benchmark "${2:-30}"
            ;;
        "backup")
            backup_current_settings
            ;;
        "restore")
            restore_settings
            ;;
        "status")
            show_current_settings
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

main "$@"
