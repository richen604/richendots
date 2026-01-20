#!/run/current-system/sw/bin/bash

set -e

# =============================================================================
# VFIO VM Cleanup Script
# =============================================================================
# This script restores the host system to normal operation after VM shutdown by:
# 1. Deallocating hugepages and reclaiming memory
# 2. Restoring CPU core availability to all processes
# 3. Resetting memory management settings to defaults
# 4. Cleaning up shared memory and temporary files
# =============================================================================

# Configuration
readonly TOTAL_CORES='0-19'        # All CPU cores
readonly LOG_FILE="/var/log/libvirt/hooks.log"
readonly MAX_RETRIES=3
readonly RETRY_DELAY=2

# =============================================================================
# Logging Functions
# =============================================================================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE" >&2
}

error() {
    log "ERROR: $1"
    exit 1
}

warn() {
    log "WARNING: $1"
}

# =============================================================================
# System Validation Functions
# =============================================================================

verify_hugepage_cleanup() {
    local remaining
    local attempts=0
    
    while [[ $attempts -lt $MAX_RETRIES ]]; do
        remaining=$(cat /proc/sys/vm/nr_hugepages)
        
        if [[ $remaining -eq 0 ]]; then
            log "Successfully deallocated all hugepages"
            return 0
        fi
        
        warn "Hugepage cleanup incomplete: $remaining hugepages remaining (attempt $((attempts + 1)))"
        
        # Force cleanup attempt
        echo 0 > /proc/sys/vm/nr_hugepages 2>/dev/null || warn "Failed to force hugepage deallocation"
        
        ((attempts++))
        sleep $RETRY_DELAY
    done
    
    warn "Failed to deallocate all hugepages after $MAX_RETRIES attempts ($remaining remaining)"
}

# =============================================================================
# CPU Management Functions
# =============================================================================

restore_cpu_affinity() {
    log "Restoring CPU affinity for all processes..."
    echo "Restoring all processes to use cores $TOTAL_CORES..."
    
    # Reset all running processes to use all CPU cores
    local restored_count=0
    for pid in $(ps -eo pid --no-headers); do
        if taskset -pc "$TOTAL_CORES" "$pid" >/dev/null 2>&1; then
            restored_count=$((restored_count + 1))
        fi
    done
    echo "Restored CPU affinity for $restored_count processes"
    
    # Reset systemd slices to use all cores
    echo "Resetting systemd slice CPU affinity to $TOTAL_CORES..."
    systemctl set-property --runtime -- user.slice AllowedCPUs="$TOTAL_CORES" || warn "Failed to reset CPU affinity for user.slice"
    systemctl set-property --runtime -- system.slice AllowedCPUs="$TOTAL_CORES" || warn "Failed to reset CPU affinity for system.slice"
    systemctl set-property --runtime -- init.scope AllowedCPUs="$TOTAL_CORES" || warn "Failed to reset CPU affinity for init.scope"
    
    # Reset workqueue CPU mask to use all cores (bitmask for all 20 cores)
    echo "Resetting writeback workqueue mask to fffff (all cores)..."
    echo "fffff" > /sys/bus/workqueue/devices/writeback/cpumask || warn "Failed to reset writeback cpumask"
    
    log "CPU affinity restored to all cores"
}

restore_cpu_governors() {
    log "Restoring CPU governors to power-saving mode..."
    
    # Set all CPU governors back to powersave for energy efficiency
    echo "Setting all CPU governors to powersave mode..."
    local cpu_count=0
    for governor in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        if [[ -f "$governor" ]]; then
            local cpu_name
            cpu_name=$(basename "$(dirname "$governor")")
            echo "Setting $cpu_name governor to powersave..."
            echo powersave > "$governor" || warn "Failed to set powersave governor for $cpu_name"
            cpu_count=$((cpu_count + 1))
        fi
    done
    echo "Set powersave governor for $cpu_count CPUs"
    
    log "CPU governors restored to powersave mode"
}

# =============================================================================
# Memory Management Functions
# =============================================================================

deallocate_hugepages() {
    log "Deallocating hugepages..."
    
    # Show hugepage info before cleanup
    echo "Hugepage info before cleanup:"
    grep -E "HugePages" /proc/meminfo
    
    # Deallocate hugepages through multiple interfaces for thorough cleanup
    echo "Deallocating 2MB hugepages via sysfs..."
    echo 0 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages 2>/dev/null || warn "Failed to deallocate 2MB hugepages"
    echo "Deallocating hugepages via proc..."
    echo 0 > /proc/sys/vm/nr_hugepages 2>/dev/null || warn "Failed to deallocate hugepages via nr_hugepages"
    
    # Wait for deallocation to complete
    echo "Waiting for hugepage deallocation to complete..."
    sleep 2
    
    # Show hugepage info after cleanup attempt
    echo "Hugepage info after cleanup attempt:"
    grep -E "HugePages" /proc/meminfo
    
    # Verify cleanup was successful
    verify_hugepage_cleanup
}

cleanup_shared_memory() {
    log "Cleaning up shared memory segments..."
    
    # Remove looking-glass shared memory file if it exists
    if [[ -f /dev/shm/looking-glass ]]; then
        echo "Removing looking-glass shared memory file..."
        rm -f /dev/shm/looking-glass || warn "Failed to remove looking-glass shared memory"
        log "Removed looking-glass shared memory"
    else
        echo "No looking-glass shared memory file found"
    fi
    
    # Clean up any hugepage files in libvirt directory
    if [[ -d /dev/hugepages/libvirt/qemu ]]; then
        echo "Cleaning hugepage files from libvirt directory..."
        local file_count
        file_count=$(find /dev/hugepages/libvirt/qemu -type f | wc -l)
        if [[ $file_count -gt 0 ]]; then
            echo "Found $file_count hugepage files to clean"
            find /dev/hugepages/libvirt/qemu -type f -delete 2>/dev/null || warn "Failed to clean hugepage files"
            log "Cleaned hugepage files from libvirt directory"
        else
            echo "No hugepage files found in libvirt directory"
        fi
    else
        echo "Libvirt hugepage directory not found"
    fi
}

force_memory_cleanup() {
    log "Performing memory cleanup and compaction..."
    
    # Show memory info before cleanup
    echo "Memory info before cleanup:"
    grep -E "(MemFree|MemAvailable|Cached)" /proc/meminfo
    
    # Force filesystem sync to ensure all data is written
    echo "Syncing filesystems..."
    sync
    
    # Drop all caches to free memory
    echo "Dropping all caches..."
    sysctl -w vm.drop_caches=3 || warn "Failed to drop caches"
    
    # Compact memory to reduce fragmentation
    echo "Compacting memory..."
    sysctl -w vm.compact_memory=1 || warn "Failed to compact memory"
    
    # Show memory info after cleanup
    echo "Memory info after cleanup:"
    grep -E "(MemFree|MemAvailable|Cached)" /proc/meminfo
    
    log "Memory cleanup completed"
}

restore_memory_settings() {
    log "Restoring default memory management settings..."
    
    # Reset memory overcommit to default (0 = heuristic overcommit)
    echo "Resetting memory overcommit to heuristic mode..."
    sysctl -w vm.overcommit_memory=0 || warn "Failed to reset overcommit_memory"
    
    # Reset swappiness to default (60 = balanced swapping)
    echo "Resetting swappiness to 60 (balanced)..."
    sysctl -w vm.swappiness=60 || warn "Failed to reset swappiness"
    
    # Reset dirty ratio to default (20%)
    echo "Resetting dirty ratio to 20%..."
    sysctl -w vm.dirty_ratio=20 || warn "Failed to reset dirty_ratio"
    
    # Re-enable transparent hugepages for general system use
    if [[ -f /sys/kernel/mm/transparent_hugepage/enabled ]]; then
        echo "Re-enabling transparent hugepages..."
        echo "Current THP setting: $(cat /sys/kernel/mm/transparent_hugepage/enabled)"
        echo always > /sys/kernel/mm/transparent_hugepage/enabled || warn "Failed to enable THP"
        echo "New THP setting: $(cat /sys/kernel/mm/transparent_hugepage/enabled)"
    fi
    
    log "Memory management settings restored to defaults"
}

# =============================================================================
# System Restoration Functions
# =============================================================================

restore_system_settings() {
    log "Restoring system settings..."
    
    # Reset VM statistics update frequency to default
    sysctl -w vm.stat_interval=1 || warn "Failed to reset vm.stat_interval"
    
    # Re-enable kernel watchdog
    sysctl -w kernel.watchdog=1 || warn "Failed to enable kernel watchdog"
    
    log "System settings restored"
}

# =============================================================================
# Main Execution Function
# =============================================================================

main() {
    log "Starting VM cleanup..."
    
    # CPU restoration
    restore_cpu_affinity
    restore_cpu_governors
    
    # System settings restoration
    restore_system_settings
    
    # Memory cleanup and restoration
    deallocate_hugepages
    cleanup_shared_memory
    force_memory_cleanup
    restore_memory_settings
    
    log "VM cleanup completed successfully"
    log "System restored to normal operation"
}

# Execute main function
main "$@"
