#!/usr/bin/env bash

# Power Benchmarking Script for ASUS Vivobook Pro 16
# This script helps benchmark different power settings to find optimal configurations

set -euo pipefail

LOGFILE="/tmp/power-benchmark-$(date +%Y%m%d-%H%M%S).log"
DURATION=${1:-60}  # Default benchmark duration in seconds

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOGFILE"
}

get_power_usage() {
    # Try multiple methods to get power consumption
    local power_uw=0

    # Method 1: Check battery power draw
    if [[ -f /sys/class/power_supply/BAT0/power_now ]]; then
        power_uw=$(cat /sys/class/power_supply/BAT0/power_now 2>/dev/null || echo 0)
    elif [[ -f /sys/class/power_supply/BAT0/current_now && -f /sys/class/power_supply/BAT0/voltage_now ]]; then
        local current_ua=$(cat /sys/class/power_supply/BAT0/current_now 2>/dev/null || echo 0)
        local voltage_uv=$(cat /sys/class/power_supply/BAT0/voltage_now 2>/dev/null || echo 0)
        power_uw=$((current_ua * voltage_uv / 1000000))
    fi

    # Convert from microwatts to watts
    echo "scale=2; $power_uw / 1000000" | bc -l
}

get_cpu_freq() {
    local total=0
    local count=0
    for freq_file in /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq; do
        if [[ -f "$freq_file" ]]; then
            local freq=$(cat "$freq_file" 2>/dev/null || echo 0)
            total=$((total + freq))
            count=$((count + 1))
        fi
    done
    if [[ $count -gt 0 ]]; then
        echo "scale=0; $total / $count / 1000" | bc -l  # Convert to MHz
    else
        echo "0"
    fi
}

get_temperature() {
    local temp=0
    if [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then
        temp=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0)
        echo "scale=1; $temp / 1000" | bc -l  # Convert to Celsius
    else
        echo "0"
    fi
}

benchmark_current_settings() {
    log "Starting benchmark for $DURATION seconds..."
    log "Current CPU governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo 'unknown')"

    local power_sum=0
    local freq_sum=0
    local temp_sum=0
    local samples=0

    for ((i=0; i<DURATION; i++)); do
        local power=$(get_power_usage)
        local freq=$(get_cpu_freq)
        local temp=$(get_temperature)

        power_sum=$(echo "$power_sum + $power" | bc -l)
        freq_sum=$(echo "$freq_sum + $freq" | bc -l)
        temp_sum=$(echo "$temp_sum + $temp" | bc -l)
        samples=$((samples + 1))

        printf "\rProgress: %d/%d - Power: %.2fW, Freq: %.0fMHz, Temp: %.1f°C" "$i" "$DURATION" "$power" "$freq" "$temp"
        sleep 1
    done

    echo  # New line after progress

    local avg_power=$(echo "scale=2; $power_sum / $samples" | bc -l)
    local avg_freq=$(echo "scale=0; $freq_sum / $samples" | bc -l)
    local avg_temp=$(echo "scale=1; $temp_sum / $samples" | bc -l)

    log "Benchmark complete!"
    log "Average Power Consumption: ${avg_power}W"
    log "Average CPU Frequency: ${avg_freq}MHz"
    log "Average Temperature: ${avg_temp}°C"
    log "---"
}

apply_governor() {
    local governor=$1
    log "Applying CPU governor: $governor"

    for cpu_dir in /sys/devices/system/cpu/cpu*/cpufreq/; do
        if [[ -f "${cpu_dir}scaling_governor" ]]; then
            echo "$governor" | sudo tee "${cpu_dir}scaling_governor" > /dev/null
        fi
    done

    sleep 2  # Allow governor to settle
}

test_governors() {
    local available_governors
    available_governors=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null || echo "")

    log "Available governors: $available_governors"
    log "Testing each governor for $DURATION seconds..."

    for governor in $available_governors; do
        log "Testing governor: $governor"
        apply_governor "$governor"
        benchmark_current_settings
        sleep 5  # Rest between tests
    done
}

show_current_status() {
    log "=== Current Power Status ==="
    log "CPU Governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo 'unknown')"
    log "Current Power Draw: $(get_power_usage)W"
    log "Average CPU Frequency: $(get_cpu_freq)MHz"
    log "CPU Temperature: $(get_temperature)°C"

    # Show auto-cpufreq status if available
    if command -v auto-cpufreq &> /dev/null; then
        log "Auto-cpufreq status:"
        sudo auto-cpufreq --stats 2>/dev/null || log "Could not get auto-cpufreq stats"
    fi
}

show_help() {
    cat << EOF
Power Benchmarking Script

Usage: $0 [options] [duration]

Options:
    -s, --status        Show current power status
    -t, --test-all      Test all available CPU governors
    -g, --governor GOV  Set specific CPU governor
    -h, --help          Show this help message

Examples:
    $0 30               Benchmark current settings for 30 seconds
    $0 --test-all 45    Test all governors for 45 seconds each
    $0 --governor powersave  Set governor to powersave
    $0 --status         Show current power status

Log file will be created at: $LOGFILE
EOF
}

main() {
    # Check if running as root for governor changes
    if [[ "${1:-}" == "--governor" ]] && [[ $EUID -ne 0 ]]; then
        log "Error: Governor changes require root privileges"
        exit 1
    fi

    case "${1:-}" in
        -h|--help)
            show_help
            exit 0
            ;;
        -s|--status)
            show_current_status
            ;;
        -t|--test-all)
            test_governors
            ;;
        -g|--governor)
            if [[ -z "${2:-}" ]]; then
                log "Error: Governor name required"
                exit 1
            fi
            apply_governor "$2"
            show_current_status
            ;;
        *)
            if [[ "${1:-}" =~ ^[0-9]+$ ]]; then
                DURATION=$1
            fi
            benchmark_current_settings
            ;;
    esac

    log "Log saved to: $LOGFILE"
}

# Check dependencies
if ! command -v bc &> /dev/null; then
    log "Error: 'bc' calculator is required but not installed"
    exit 1
fi

main "$@"
