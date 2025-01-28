#!/run/current-system/sw/bin/bash
# https://rokups.github.io/#!pages/gaming-vm-performance.md

set -e

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a /var/log/libvirt/hooks.log >&2
}

error() {
    log "ERROR: $1"
    exit 1
}

main() {
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root"
    fi

    log "Starting VM preparation..."

    # Reset PCI device
    if [[ -e /sys/bus/pci/devices/0000:08:00.0/reset ]]; then
        echo 1 > /sys/bus/pci/devices/0000:08:00.0/reset || error "Failed to reset PCI device"
    else
        log "PCI device reset file not found, skipping reset"
    fi

    HOST_CORES='14-19'
    VIRT_CORES='0-13' 

    # Function to convert core range to hexadecimal mask
    cores_to_mask() {
        local cores="$1"
        local mask=0
        for core in $(seq ${cores/-/ }); do
            mask=$((mask | 1<<core))
        done
        printf "%x" "$mask"
    }

    HOST_CORES_MASK=$(cores_to_mask "$HOST_CORES")
    VIRT_CORES_MASK=$(cores_to_mask "$VIRT_CORES")

    pin_vm_cores() {
        log "Pinning tasks to virtual cores..."
        for pid in $(ps -eo pid --no-headers); do
            taskset -pc $VIRT_CORES $pid > /dev/null 2>&1 || true
        done
    }

    # Set CPU affinity for systemd slices
    systemctl set-property --runtime -- user.slice AllowedCPUs=$HOST_CORES || log "Failed to set CPU affinity for user.slice"
    systemctl set-property --runtime -- system.slice AllowedCPUs=$HOST_CORES || log "Failed to set CPU affinity for system.slice"
    systemctl set-property --runtime -- init.scope AllowedCPUs=$HOST_CORES || log "Failed to set CPU affinity for init.scope"

    # Drop caches and compact memory before allocating hugepages
    sync
    sysctl -w vm.drop_caches=3 || log "Failed to drop caches"
    sysctl -w vm.compact_memory=1 || log "Failed to compact memory"

    # Hugepages allocation
    sysctl -w vm.nr_hugepages=31744 || log "Failed to allocate hugepages"

    # Shield VM cores
    pin_vm_cores

    # Reduce VM jitter and set other kernel parameters
    sysctl -w vm.stat_interval=120 || log "Failed to set vm.stat_interval"
    sysctl -w kernel.watchdog=0 || log "Failed to disable kernel watchdog"
    echo $HOST_CORES_MASK > /sys/bus/workqueue/devices/writeback/cpumask || log "Failed to set writeback cpumask"
    
    # Check if transparent hugepages are available
    if [[ -f /sys/kernel/mm/transparent_hugepage/enabled ]]; then
        echo never > /sys/kernel/mm/transparent_hugepage/enabled || log "Failed to disable THP"
    else
        log "Transparent hugepages not available, skipping THP disable"
    fi
    
    # Force P-states to P0
    for governor in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        echo performance > "$governor" || log "Failed to set CPU governor to performance"
    done

    log "VM preparation completed successfully"
}

main

# TODO: Implement NVIDIA driver check and VFIO setup for NixOS
# This part needs to be adapted to NixOS-specific commands and paths
