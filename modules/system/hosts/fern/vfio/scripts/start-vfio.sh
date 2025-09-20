#!/run/current-system/sw/bin/bash

set -e

# =============================================================================
# VFIO VM Preparation Script
# =============================================================================
# This script prepares the host system for optimal VM performance by:
# 1. Allocating hugepages for VM memory
# 2. Isolating CPU cores for VM use
# 3. Optimizing memory management settings
# 4. Configuring system for low-latency operation
# =============================================================================

# Configuration
readonly HUGEPAGES_REQUIRED=18432  # 36GB = 18432 * 2MB hugepages (32GB VM + 4GB QEMU overhead)
# Host reserved CPUs: 2 P-cores (0-3) + 1 E-core (16)
readonly HOST_CORES='0-3,16'
# VM CPUs: remaining 6 P-cores (4-15) + remaining E-cores (17-19)
readonly VIRT_CORES='4-15,17-19'
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

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root"
    fi
}

check_hugepages_available() {
    local current_hugepages
    current_hugepages=$(cat /proc/sys/vm/nr_hugepages)
    
    if [[ $current_hugepages -ne 0 ]]; then
        error "Hugepages already allocated ($current_hugepages). Run stop-vfio.sh first."
    fi
}

verify_hugepage_allocation() {
    local allocated
    local free_hugepages
    local attempts=0
    
    while [[ $attempts -lt $MAX_RETRIES ]]; do
        allocated=$(cat /proc/sys/vm/nr_hugepages)
        free_hugepages=$(grep HugePages_Free /proc/meminfo | awk '{print $2}')
        
        if [[ $allocated -eq $HUGEPAGES_REQUIRED ]] && [[ $free_hugepages -eq $HUGEPAGES_REQUIRED ]]; then
            log "Successfully allocated $allocated hugepages ($free_hugepages free)"
            return 0
        fi
        
        warn "Hugepage allocation incomplete: $allocated allocated, $free_hugepages free (attempt $((attempts + 1)))"
        ((attempts++))
        sleep $RETRY_DELAY
    done
    
    error "Failed to allocate required hugepages after $MAX_RETRIES attempts"
}

# =============================================================================
# CPU Management Functions
# =============================================================================

setup_cpu_isolation() {
    log "Configuring CPU isolation..."
    echo "Host cores: $HOST_CORES"
    echo "VM cores: $VIRT_CORES"
    
    # Pin host processes to host cores only
    log "Pinning host tasks to cores $HOST_CORES..."
    local pinned_count=0
    for pid in $(ps -eo pid --no-headers); do
        if taskset -pc "$HOST_CORES" "$pid" >/dev/null 2>&1; then
            pinned_count=$((pinned_count + 1))
        fi
    done
    echo "Pinned $pinned_count processes to host cores"
    
    # Configure systemd slices for CPU affinity
    echo "Setting systemd slice CPU affinity to $HOST_CORES..."
    systemctl set-property --runtime -- user.slice AllowedCPUs="$HOST_CORES" || warn "Failed to set CPU affinity for user.slice"
    systemctl set-property --runtime -- system.slice AllowedCPUs="$HOST_CORES" || warn "Failed to set CPU affinity for system.slice"
    systemctl set-property --runtime -- init.scope AllowedCPUs="$HOST_CORES" || warn "Failed to set CPU affinity for init.scope"
    
    # Configure workqueue CPU mask to avoid VM cores (requires hex bitmask)
    # For cores 12-19: 0xFF000 (bits 12-19 set)
    local writeback_mask="ff000"
    echo "Setting writeback workqueue mask to $writeback_mask (cores $HOST_CORES)"
    echo "$writeback_mask" > /sys/bus/workqueue/devices/writeback/cpumask || warn "Failed to set writeback cpumask"
    
    log "CPU isolation configured successfully"
}

setup_cpu_performance() {
    log "Configuring CPU performance settings..."
    
    # Set all CPU governors to performance mode for maximum frequency
    echo "Setting all CPU governors to performance mode..."
    local cpu_count=0
    for governor in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        if [[ -f "$governor" ]]; then
            local cpu_name
            cpu_name=$(basename "$(dirname "$governor")")
            echo "Setting $cpu_name governor to performance..."
            echo performance > "$governor" || warn "Failed to set performance governor for $cpu_name"
            cpu_count=$((cpu_count + 1))
        fi
    done
    echo "Set performance governor for $cpu_count CPUs"
    
    log "CPU performance settings applied"
}

# =============================================================================
# Memory Management Functions
# =============================================================================

prepare_memory_system() {
    log "Preparing memory system for hugepage allocation..."
    
    # Show current memory state
    echo "Current memory info:"
    grep -E "(MemTotal|MemFree|MemAvailable|Hugepages)" /proc/meminfo
    
    # Configure memory overcommit policy (2 = strict accounting)
    echo "Setting memory overcommit policy to strict accounting..."
    sysctl -w vm.overcommit_memory=2 || warn "Failed to set overcommit_memory"
    
    # Minimize swapping (1 = swap only when necessary)
    echo "Setting swappiness to 1 (minimal swapping)..."
    sysctl -w vm.swappiness=1 || warn "Failed to set swappiness"
    
    # Reduce dirty page ratio for better memory management
    echo "Setting dirty ratio to 5% for better memory management..."
    sysctl -w vm.dirty_ratio=5 || warn "Failed to set dirty_ratio"
    
    # Force filesystem sync to ensure clean state
    echo "Syncing filesystems..."
    sync
    
    # Drop all caches to free maximum memory for hugepage allocation
    echo "Dropping all caches to free memory..."
    sysctl -w vm.drop_caches=3 || warn "Failed to drop caches"
    
    # Compact memory to reduce fragmentation
    echo "Compacting memory to reduce fragmentation..."
    sysctl -w vm.compact_memory=1 || warn "Failed to compact memory"
    
    # Show memory state after preparation
    echo "Memory info after preparation:"
    grep -E "(MemFree|MemAvailable)" /proc/meminfo
    
    log "Memory system prepared"
}

allocate_hugepages() {
    log "Allocating hugepages..."
    
    # Clear any existing hugepages first
    echo "Clearing any existing hugepages..."
    echo 0 > /proc/sys/vm/nr_hugepages 2>/dev/null || warn "Failed to clear existing hugepages"
    sleep 1
    
    # Show hugepage info before allocation
    echo "Hugepage info before allocation:"
    grep -E "HugePages" /proc/meminfo
    
    # Allocate required hugepages
    log "Requesting $HUGEPAGES_REQUIRED hugepages (36GB)..."
    sysctl -w vm.nr_hugepages="$HUGEPAGES_REQUIRED" || error "Failed to allocate hugepages"
    
    # Show hugepage info after allocation attempt
    echo "Hugepage info after allocation attempt:"
    grep -E "HugePages" /proc/meminfo
    
    # Verify allocation was successful
    verify_hugepage_allocation
}

setup_memory_optimizations() {
    log "Applying memory optimizations..."
    
    # Disable transparent hugepages (conflicts with explicit hugepages)
    if [[ -f /sys/kernel/mm/transparent_hugepage/enabled ]]; then
        echo "Disabling transparent hugepages..."
        echo "Current THP setting: $(cat /sys/kernel/mm/transparent_hugepage/enabled)"
        echo never > /sys/kernel/mm/transparent_hugepage/enabled || warn "Failed to disable THP"
        echo "New THP setting: $(cat /sys/kernel/mm/transparent_hugepage/enabled)"
    fi
    
    # Reduce VM statistics update frequency to minimize overhead
    echo "Setting VM statistics interval to 120 seconds..."
    sysctl -w vm.stat_interval=120 || warn "Failed to set vm.stat_interval"
    
    # Disable kernel watchdog to reduce interruptions
    echo "Disabling kernel watchdog..."
    sysctl -w kernel.watchdog=0 || warn "Failed to disable kernel watchdog"
    
    log "Memory optimizations applied"
}

# =============================================================================
# Memory Limit Configuration Functions
# =============================================================================

setup_memory_limits() {
    log "Setting up memory limits for VM processes..."
    
    # Create cgroup for VM memory limits (38GB = 36GB hugepages + 2GB buffer)
    local vm_memory_limit="40802189312"  # 38GB in bytes
    local cgroup_path="/sys/fs/cgroup/libvirt-vm"
    
    if [[ -d "/sys/fs/cgroup" ]]; then
        echo "Creating cgroup for VM memory limits..."
        mkdir -p "$cgroup_path" || warn "Failed to create cgroup directory"
        
        # Set memory limit (cgroups v2)
        if [[ -f "$cgroup_path/memory.max" ]]; then
            echo "$vm_memory_limit" > "$cgroup_path/memory.max" || warn "Failed to set memory.max"
            echo "Set cgroups v2 memory limit to 38GB"
        # Set memory limit (cgroups v1)
        elif [[ -f "$cgroup_path/memory.limit_in_bytes" ]]; then
            echo "$vm_memory_limit" > "$cgroup_path/memory.limit_in_bytes" || warn "Failed to set memory.limit_in_bytes"
            echo "Set cgroups v1 memory limit to 38GB"
        else
            warn "Could not find cgroup memory control files"
        fi
        
        # Disable swap for this cgroup to prevent memory leakage
        if [[ -f "$cgroup_path/memory.swap.max" ]]; then
            echo "0" > "$cgroup_path/memory.swap.max" || warn "Failed to disable swap for cgroup"
            echo "Disabled swap for VM cgroup"
        elif [[ -f "$cgroup_path/memory.swappiness" ]]; then
            echo "0" > "$cgroup_path/memory.swappiness" || warn "Failed to set swappiness for cgroup"
            echo "Set swappiness to 0 for VM cgroup"
        fi
        
        log "Memory limits configured successfully"
    else
        warn "Cgroups not available, skipping memory limits"
    fi
}

# =============================================================================
# Hardware Configuration Functions
# =============================================================================

reset_pci_device() {
    local pci_device="0000:08:00.0"
    
    if [[ -e "/sys/bus/pci/devices/$pci_device/reset" ]]; then
        log "Resetting PCI device $pci_device..."
        echo 1 > "/sys/bus/pci/devices/$pci_device/reset" || warn "Failed to reset PCI device $pci_device"
    else
        log "PCI device $pci_device reset not available, skipping"
    fi
}

# =============================================================================
# Main Execution Function
# =============================================================================

main() {
    log "Starting VM preparation..."
    
    # System validation
    check_root
    check_hugepages_available
    
    # Hardware preparation
    reset_pci_device
    
    # Memory system preparation
    prepare_memory_system
    allocate_hugepages
    setup_memory_optimizations
    setup_memory_limits
    
    # CPU configuration
    setup_cpu_isolation
    setup_cpu_performance
    
    log "VM preparation completed successfully"
    log "System ready for VM startup with $HUGEPAGES_REQUIRED hugepages allocated"
}

# Execute main function
main "$@"
