#!/usr/bin/env nix-shell
#! nix-shell -i bash -p gum

NVIDIA_GPU="0000:08:00.0"
NVIDIA_AUDIO="0000:08:00.1"

# Debug mode - set to 1 to enable verbose debug output
DEBUG=${DEBUG:-0}
TIMEOUT=${TIMEOUT:-30}  # Default timeout in seconds

# Check if gum is available, provide fallbacks if not
if ! command -v gum >/dev/null 2>&1; then
    # Fallback functions when gum is not available
    gum() {
        case "$1" in
            style)
                shift
                # Skip style arguments and just echo the message
                while [[ $1 == --* ]]; do
                    shift 2 2>/dev/null || shift 1
                done
                echo "$@"
                ;;
            spin)
                shift
                # Skip spin arguments and run the command directly
                while [[ $1 == --* ]]; do
                    shift 2 2>/dev/null || shift 1
                done
                if [ "$1" = "--" ]; then
                    shift
                    "$@"
                fi
                ;;
            *)
                echo "$@"
                ;;
        esac
    }
fi

debug_log() {
    if [ "$DEBUG" = "1" ]; then
        gum style --foreground "#888888" "DEBUG: $1"
    fi
}

# Wait for a device to appear after PCI rescan
wait_for_device() {
    local device="$1"
    local max_wait=10
    local count=0
    
    debug_log "Waiting for device $device to appear..."
    while [ $count -lt $max_wait ]; do
        if [ -e "/sys/bus/pci/devices/$device" ]; then
            debug_log "Device $device appeared after ${count}s"
            return 0
        fi
        sleep 1
        count=$((count + 1))
    done
    
    gum style --foreground "#ff0000" "WARNING: Device $device did not appear after ${max_wait}s"
    return 1
}

# Timeout wrapper for commands that might hang
timeout_cmd() {
    local timeout_duration="$1"
    shift
    local description="$1"
    shift
    
    debug_log "Running with ${timeout_duration}s timeout: $description"
    if timeout "$timeout_duration" "$@"; then
        debug_log "Command completed successfully: $description"
        return 0
    else
        local exit_code=$?
        if [ $exit_code -eq 124 ]; then
            gum style --foreground "#ff0000" "TIMEOUT: $description (${timeout_duration}s)"
        else
            gum style --foreground "#ff0000" "FAILED: $description (exit code: $exit_code)"
        fi
        return $exit_code
    fi
}

# Simple and robust binding functions
bind_to_vfio() {
    gum style --foreground "#0087ff" --bold "BINDING TO VFIO"
    debug_log "Starting VFIO binding process"
    
    # Check for processes and force kill them
    debug_log "Checking for NVIDIA processes..."
    # Get NVIDIA processes more reliably
    if nvidia_processes=$(sudo lsof /dev/nvidia* 2>/dev/null | awk 'NR>1 {print $2}' | sort -u | tr '\n' ' ') && [ -n "$nvidia_processes" ]; then
        gum style --foreground "#ff8800" "WARNING: NVIDIA processes detected"
        if [ -n "$nvidia_processes" ]; then
            ps -p $nvidia_processes --no-headers 2>/dev/null | sed 's/^/  /' | gum style --foreground "#999999"
            gum style --foreground "#ff8800" "Terminating NVIDIA processes..."
            debug_log "Killing PIDs: $nvidia_processes"
            if [ -n "$nvidia_processes" ]; then
                sudo kill -9 $nvidia_processes 2>/dev/null || true
            fi
            gum style --foreground "#00aa00" "Processes terminated"
        fi
    else
        debug_log "No NVIDIA processes found"
    fi
    
    # Unbind from current drivers first
    gum style --foreground "#0087ff" "Unbinding devices from current drivers..."
    for device in "$NVIDIA_GPU" "$NVIDIA_AUDIO"; do
        if [ -e "/sys/bus/pci/devices/$device/driver" ]; then
            current_driver=$(basename "$(readlink "/sys/bus/pci/devices/$device/driver")")
            echo "  Unbinding $device from $current_driver"
            debug_log "About to unbind $device from $current_driver"
            if timeout "$TIMEOUT" sudo bash -c "echo \"$device\" | tee \"/sys/bus/pci/drivers/$current_driver/unbind\" >/dev/null 2>&1"; then
                echo "  Success: unbound $device from $current_driver"
            else
                echo "  Warning: failed to unbind $device from $current_driver"
            fi
        else
            echo "  Info: $device not bound to any driver"
        fi
    done
    
    # Unload nvidia modules to prevent rebinding
    gum style --foreground "#0087ff" "Unloading NVIDIA modules..."
    debug_log "Attempting to unload nvidia_uvm"
    if timeout "$TIMEOUT" sudo rmmod nvidia_uvm 2>/dev/null; then
        echo "  Success: nvidia_uvm unloaded"
    else
        echo "  Info: nvidia_uvm (not loaded or in use)"
    fi
    
    debug_log "Attempting to unload nvidia"
    if timeout "$TIMEOUT" sudo rmmod nvidia 2>/dev/null; then
        echo "  Success: nvidia unloaded"
    else
        echo "  Info: nvidia (not loaded or in use)"
    fi
    
    # Load VFIO modules
    gum style --foreground "#0087ff" "Loading VFIO modules..."
    debug_log "Loading VFIO modules: vfio-pci, vfio_iommu_type1, vfio"
    timeout_cmd 15 "Load VFIO modules" sudo modprobe vfio-pci vfio_iommu_type1 vfio || true
    
    # Set driver overrides to vfio-pci BEFORE removing devices
    gum style --foreground "#0087ff" "Setting driver overrides..."
    debug_log "Setting driver override for $NVIDIA_GPU to vfio-pci"
    timeout_cmd 5 "Set GPU driver override" sudo bash -c "echo 'vfio-pci' | tee '/sys/bus/pci/devices/$NVIDIA_GPU/driver_override' >/dev/null"
    debug_log "Setting driver override for $NVIDIA_AUDIO to vfio-pci"
    timeout_cmd 5 "Set audio driver override" sudo bash -c "echo 'vfio-pci' | tee '/sys/bus/pci/devices/$NVIDIA_AUDIO/driver_override' >/dev/null"
    
    # Remove and rescan to apply the driver override
    gum style --foreground "#0087ff" "Rescanning PCI bus..."
    debug_log "Removing GPU device $NVIDIA_GPU"
    if timeout "$TIMEOUT" sudo bash -c "echo 1 | tee \"/sys/bus/pci/devices/$NVIDIA_GPU/remove\" >/dev/null 2>&1"; then
        echo "  Success: GPU device removed"
    else
        echo "  Warning: failed to remove GPU device"
    fi
    
    debug_log "Removing audio device $NVIDIA_AUDIO"
    if timeout "$TIMEOUT" sudo bash -c "echo 1 | tee \"/sys/bus/pci/devices/$NVIDIA_AUDIO/remove\" >/dev/null 2>&1"; then
        echo "  Success: audio device removed"
    else
        echo "  Warning: failed to remove audio device"
    fi
    
    debug_log "Rescanning PCI bus"
    if timeout "$TIMEOUT" sudo bash -c "echo 1 | tee /sys/bus/pci/rescan >/dev/null 2>&1"; then
        echo "  Success: PCI bus rescanned"
    else
        echo "  Warning: failed to rescan PCI bus"
    fi
    
    echo "  Waiting 3 seconds for devices to settle..."
    sleep 3
    
    # Wait for devices to reappear and verify they exist
    for device in "$NVIDIA_GPU" "$NVIDIA_AUDIO"; do
        wait_for_device "$device"
    done
    
    # Verify and force bind if necessary
    debug_log "Verifying device binding to vfio-pci"
    bind_success=true
    
    for device in "$NVIDIA_GPU" "$NVIDIA_AUDIO"; do
        debug_log "Checking binding status for $device"
        if [ ! -e "/sys/bus/pci/devices/$device" ]; then
            gum style --foreground "#ff0000" "ERROR: Device $device not found after rescan"
            bind_success=false
            continue
        fi
        
        if [ -e "/sys/bus/pci/devices/$device/driver" ]; then
            current_driver=$(basename "$(readlink "/sys/bus/pci/devices/$device/driver")")
            debug_log "Device $device is bound to $current_driver"
            if [ "$current_driver" != "vfio-pci" ]; then
                gum style --foreground "#ff8800" "Force binding $device to vfio-pci (currently $current_driver)"
                debug_log "Unbinding $device from $current_driver"
                timeout_cmd 15 "Unbind from $current_driver" sudo bash -c "echo '$device' | tee '/sys/bus/pci/drivers/$current_driver/unbind' >/dev/null 2>&1" || true
                debug_log "Binding $device to vfio-pci"
                if ! timeout_cmd 15 "Bind to vfio-pci" sudo bash -c "echo '$device' | tee /sys/bus/pci/drivers/vfio-pci/bind >/dev/null 2>&1"; then
                    gum style --foreground "#ff0000" "ERROR: Failed to bind $device to vfio-pci"
                    bind_success=false
                fi
            fi
        else
            debug_log "Device $device has no driver, force binding to vfio-pci"
            gum style --foreground "#ff8800" "Force binding $device to vfio-pci"
            if ! timeout_cmd 15 "Bind to vfio-pci" sudo bash -c "echo '$device' | tee /sys/bus/pci/drivers/vfio-pci/bind >/dev/null 2>&1"; then
                gum style --foreground "#ff0000" "ERROR: Failed to bind $device to vfio-pci"
                bind_success=false
            fi
        fi
    done
    
    if [ "$bind_success" = "true" ]; then
        gum style --foreground "#00aa00" --bold "SUCCESS: Devices bound to vfio-pci"
    else
        gum style --foreground "#ff0000" --bold "ERROR: Some devices failed to bind to vfio-pci"
        return 1
    fi
}

bind_to_nvidia() {
    gum style --foreground "#00aa00" --bold "BINDING TO NVIDIA"
    debug_log "Starting NVIDIA binding process"
    
    # First unbind from vfio-pci if currently bound
    gum style --foreground "#0087ff" "Unbinding devices from vfio-pci..."
    for device in "$NVIDIA_GPU" "$NVIDIA_AUDIO"; do
        if [ -e "/sys/bus/pci/devices/$device/driver" ]; then
            current_driver=$(basename "$(readlink "/sys/bus/pci/devices/$device/driver")")
            if [ "$current_driver" = "vfio-pci" ]; then
                echo "  Unbinding $device from vfio-pci"
                debug_log "About to unbind $device from vfio-pci"
                if timeout "$TIMEOUT" sudo bash -c "echo \"$device\" | tee \"/sys/bus/pci/drivers/vfio-pci/unbind\" >/dev/null 2>&1"; then
                    echo "  Success: unbound $device from vfio-pci"
                else
                    echo "  Warning: failed to unbind $device from vfio-pci"
                fi
            fi
        fi
    done
    
    # Clear driver overrides
    gum style --foreground "#0087ff" "Clearing driver overrides..."
    debug_log "Clearing driver override for $NVIDIA_GPU"
    timeout_cmd 5 "Clear GPU driver override" sudo bash -c "echo '' | tee '/sys/bus/pci/devices/$NVIDIA_GPU/driver_override' >/dev/null"
    debug_log "Clearing driver override for $NVIDIA_AUDIO"
    timeout_cmd 5 "Clear audio driver override" sudo bash -c "echo '' | tee '/sys/bus/pci/devices/$NVIDIA_AUDIO/driver_override' >/dev/null"
    
    # Remove vfio modules to prevent auto-rebinding
    gum style --foreground "#0087ff" "Removing VFIO modules..."
    debug_log "Attempting to remove vfio_pci"
    if timeout "$TIMEOUT" sudo rmmod vfio_pci 2>/dev/null; then
        echo "  Success: vfio_pci removed"
    else
        echo "  Info: vfio_pci (not loaded or in use)"
    fi
    
    debug_log "Attempting to remove vfio_iommu_type1"
    if timeout "$TIMEOUT" sudo rmmod vfio_iommu_type1 2>/dev/null; then
        echo "  Success: vfio_iommu_type1 removed"
    else
        echo "  Info: vfio_iommu_type1 (not loaded or in use)"
    fi
    
    debug_log "Attempting to remove vfio"
    if timeout "$TIMEOUT" sudo rmmod vfio 2>/dev/null; then
        echo "  Success: vfio removed"
    else
        echo "  Info: vfio (not loaded or in use)"
    fi
    
    # Remove and rescan to let the system rebind to default drivers
    gum style --foreground "#0087ff" "Rescanning PCI bus..."
    debug_log "Removing GPU device $NVIDIA_GPU"
    if timeout "$TIMEOUT" sudo bash -c "echo 1 | tee \"/sys/bus/pci/devices/$NVIDIA_GPU/remove\" >/dev/null 2>&1"; then
        echo "  Success: GPU device removed"
    else
        echo "  Warning: failed to remove GPU device"
    fi
    
    debug_log "Removing audio device $NVIDIA_AUDIO"
    if timeout "$TIMEOUT" sudo bash -c "echo 1 | tee \"/sys/bus/pci/devices/$NVIDIA_AUDIO/remove\" >/dev/null 2>&1"; then
        echo "  Success: audio device removed"
    else
        echo "  Warning: failed to remove audio device"
    fi
    
    debug_log "Rescanning PCI bus"
    if timeout "$TIMEOUT" sudo bash -c "echo 1 | tee /sys/bus/pci/rescan >/dev/null 2>&1"; then
        echo "  Success: PCI bus rescanned"
    else
        echo "  Warning: failed to rescan PCI bus"
    fi
    
    echo "  Waiting 3 seconds for devices to settle..."
    sleep 3
    
    # Wait for devices to reappear
    for device in "$NVIDIA_GPU" "$NVIDIA_AUDIO"; do
        wait_for_device "$device"
    done
    
    # Load NVIDIA drivers first
    gum style --foreground "#0087ff" "Loading NVIDIA drivers..."
    debug_log "Attempting to load nvidia module"
    if timeout "$TIMEOUT" sudo modprobe nvidia; then
        echo "  Success: nvidia loaded"
    else
        echo "  Warning: nvidia failed to load"
    fi
    
    debug_log "Attempting to load nvidia_uvm module"
    if timeout "$TIMEOUT" sudo modprobe nvidia_uvm; then
        echo "  Success: nvidia_uvm loaded"
    else
        echo "  Warning: nvidia_uvm failed to load"
    fi
    
    # Force bind to correct drivers if they didn't bind automatically
    bind_success=true
    
    debug_log "Checking if GPU needs manual binding to nvidia driver"
    if [ ! -e "/sys/bus/pci/devices/$NVIDIA_GPU/driver" ] || [ "$(basename "$(readlink "/sys/bus/pci/devices/$NVIDIA_GPU/driver" 2>/dev/null)" 2>/dev/null)" != "nvidia" ]; then
        gum style --foreground "#ff8800" "Force binding GPU to nvidia driver"
        debug_log "Force binding $NVIDIA_GPU to nvidia driver"
        if ! timeout_cmd 15 "Bind GPU to nvidia" sudo bash -c "echo '$NVIDIA_GPU' | tee /sys/bus/pci/drivers/nvidia/bind >/dev/null 2>&1"; then
            gum style --foreground "#ff0000" "ERROR: Failed to bind GPU to nvidia driver"
            bind_success=false
        fi
    fi
    
    debug_log "Checking if audio needs manual binding to snd_hda_intel driver"
    if [ ! -e "/sys/bus/pci/devices/$NVIDIA_AUDIO/driver" ] || [ "$(basename "$(readlink "/sys/bus/pci/devices/$NVIDIA_AUDIO/driver" 2>/dev/null)" 2>/dev/null)" != "snd_hda_intel" ]; then
        gum style --foreground "#ff8800" "Force binding audio to snd_hda_intel driver"
        debug_log "Force binding $NVIDIA_AUDIO to snd_hda_intel driver"
        if ! timeout_cmd 15 "Bind audio to snd_hda_intel" sudo bash -c "echo '$NVIDIA_AUDIO' | tee /sys/bus/pci/drivers/snd_hda_intel/bind >/dev/null 2>&1"; then
            gum style --foreground "#ff0000" "ERROR: Failed to bind audio to snd_hda_intel driver"
            bind_success=false
        fi
    fi
    
    if [ "$bind_success" = "true" ]; then
        gum style --foreground "#00aa00" --bold "SUCCESS: Devices bound to nvidia/snd_hda_intel"
    else
        gum style --foreground "#ff0000" --bold "ERROR: Some devices failed to bind to nvidia drivers"
        return 1
    fi
}

show_status() {
    gum style --foreground "#0087ff" --bold "DEVICE STATUS"
    echo
    
    for device in "$NVIDIA_GPU" "$NVIDIA_AUDIO"; do
        if [ -e "/sys/bus/pci/devices/$device" ]; then
            driver_override=$(cat "/sys/bus/pci/devices/$device/driver_override" 2>/dev/null || echo "")
            # Handle empty or null driver override properly
            if [ -z "$driver_override" ] || [ "$driver_override" = "(null)" ]; then
                driver_override="none"
            fi
            
            if [ -e "/sys/bus/pci/devices/$device/driver" ]; then
                current_driver=$(basename "$(readlink "/sys/bus/pci/devices/$device/driver")")
                # Color code the driver status
                if [ "$current_driver" = "vfio-pci" ]; then
                    driver_color="#7f7fff"  # Blue for VFIO
                elif [ "$current_driver" = "nvidia" ]; then
                    driver_color="#00aa00"   # Green for NVIDIA
                elif [ "$current_driver" = "snd_hda_intel" ]; then
                    driver_color="#00aa00"   # Green for audio
                else
                    driver_color="#ff8800"  # Orange for other
                fi
            else
                current_driver="none"
                driver_color="#ff0000" # Red for none
            fi
            
            gum style --foreground $driver_color "$device: driver=$current_driver, override=$driver_override"
        else
            gum style --foreground "#ff0000" "$device: not found"
        fi
    done
    
    # Show loaded kernel modules
    echo
    gum style --foreground "#0087ff" "Kernel modules:"
    if lsmod | grep -q "^nvidia "; then
        gum style --foreground "#00aa00" "  nvidia: loaded"
    else
        gum style --foreground "#ff0000" "  nvidia: not loaded"
    fi
    
    if lsmod | grep -q "^nvidia_uvm "; then
        gum style --foreground "#00aa00" "  nvidia_uvm: loaded"
    else
        gum style --foreground "#ff0000" "  nvidia_uvm: not loaded"
    fi
    
    if lsmod | grep -q "^vfio_pci "; then
        gum style --foreground "#7f7fff" "  vfio_pci: loaded"
    else
        gum style --foreground "#ff0000" "  vfio_pci: not loaded"
    fi
    
    if lsmod | grep -q "^vfio "; then
        gum style --foreground "#7f7fff" "  vfio: loaded"
    else
        gum style --foreground "#ff0000" "  vfio: not loaded"
    fi
    
    echo
    gum style --foreground "#0087ff" "NVIDIA device usage:"
    # Use lsof instead of fuser for better reliability
    if nvidia_processes=$(sudo lsof /dev/nvidia* 2>/dev/null | awk 'NR>1 {print $2}' | sort -u | tr '\n' ' ') && [ -n "$nvidia_processes" ]; then
        ps -p $nvidia_processes --no-headers 2>/dev/null | sed 's/^/  /' | gum style --foreground "#ff8800"
    else
        gum style --foreground "#00aa00" "  No processes using NVIDIA devices"
    fi
}

case "$1" in
    bind|vfio)
        bind_to_vfio
        ;;
    unbind|nvidia)
        bind_to_nvidia
        ;;
    status)
        show_status
        ;;
    *)
        gum style --foreground "#ff0000" --bold "INVALID USAGE"
        echo
        gum style --foreground "#0087ff" "Usage: $0 {bind|unbind|status}"
        gum style --foreground "#999999" "  bind/vfio   - Bind devices to VFIO for VM passthrough"
        gum style --foreground "#999999" "  unbind/nvidia - Bind devices back to NVIDIA drivers"  
        gum style --foreground "#999999" "  status      - Show current device status"
        echo
        gum style --foreground "#888888" "Environment variables:"
        gum style --foreground "#888888" "  DEBUG=1        - Enable verbose debug output"
        gum style --foreground "#888888" "  TIMEOUT=N      - Set timeout in seconds (default: 30)"
        echo
        gum style --foreground "#888888" "Examples:"
        gum style --foreground "#888888" "  DEBUG=1 $0 bind           - Run with debug output"
        gum style --foreground "#888888" "  TIMEOUT=60 $0 bind        - Use 60-second timeout"
        gum style --foreground "#888888" "  DEBUG=1 TIMEOUT=60 $0 bind - Both debug and custom timeout"
        exit 1
        ;;
esac
