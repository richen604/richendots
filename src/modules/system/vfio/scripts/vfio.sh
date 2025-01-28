#!/usr/bin/env bash

NVIDIA_GPU="0000:08:00.0"
NVIDIA_AUDIO="0000:08:00.1"

bind_device() {
    local device=$1
    local from_driver=$2
    local to_driver=$3
    
    echo "Unbinding $device from $from_driver..."
    if [ "$from_driver" = "nvidia" ]; then
        # Disable DRM modesetting before unbinding
        if lsmod | grep -q nvidia_drm; then
            sudo rmmod nvidia_drm
            sudo rmmod nvidia_uvm
            sudo rmmod nvidia_modeset
            sudo rmmod nvidia
        fi
    fi

    if [ -e "/sys/bus/pci/drivers/$from_driver/$device" ]; then
        echo -n "$device" | sudo tee "/sys/bus/pci/drivers/$from_driver/unbind" >/dev/null
    fi
    
    # Make sure the new driver is loaded
    if [ "$to_driver" = "nvidia" ]; then
        # Remove vfio drivers first
        sudo modprobe -r vfio-pci vfio_iommu_type1 vfio
        # Load NVIDIA drivers in correct order
        sudo modprobe nvidia
        sudo modprobe nvidia_modeset
        sudo modprobe nvidia_uvm
        sudo modprobe nvidia_drm modeset=1
    elif [ "$to_driver" = "vfio-pci" ]; then
        # NVIDIA drivers are already unloaded above
        sudo modprobe vfio-pci vfio_iommu_type1 vfio
    fi
    
    # Remove the device ID from the old driver and add it to the new one
    echo "Binding $device to $to_driver..."
    echo -n "$device" | sudo tee "/sys/bus/pci/drivers/$to_driver/new_id" >/dev/null 2>&1 || true
    echo -n "$device" | sudo tee "/sys/bus/pci/drivers/$to_driver/bind" >/dev/null
    
    # Verify the binding
    if [ -e "/sys/bus/pci/drivers/$to_driver/$device" ]; then
        echo "Successfully bound $device to $to_driver"
    else
        echo "Failed to bind $device to $to_driver"
    fi
}

bind_gpu() {
    # Bind GPU
    bind_device "$NVIDIA_GPU" "nvidia" "vfio-pci"
    sleep 1
    # Bind Audio
    bind_device "$NVIDIA_AUDIO" "snd_hda_intel" "vfio-pci"  # Changed from nvidia to snd_hda_intel
    echo "GPU and Audio devices binding completed"
}

unbind_gpu() {
    # Unbind Audio
    bind_device "$NVIDIA_AUDIO" "vfio-pci" "snd_hda_intel"  # Changed to snd_hda_intel
    sleep 1
    # Unbind GPU
    bind_device "$NVIDIA_GPU" "vfio-pci" "nvidia"
    echo "GPU and Audio devices unbinding completed"
}

status() {
    echo "Checking device status..."
    echo
    
    echo "GPU ($NVIDIA_GPU):"
    if [ -e "/sys/bus/pci/devices/$NVIDIA_GPU" ]; then
        driver=$(readlink "/sys/bus/pci/devices/$NVIDIA_GPU/driver" 2>/dev/null)
        driver=${driver##*/}
        echo "  Driver in use: ${driver:-None}"
    else
        echo "  Not found"
    fi

    echo
    echo "Audio ($NVIDIA_AUDIO):"
    if [ -e "/sys/bus/pci/devices/$NVIDIA_AUDIO" ]; then
        driver=$(readlink "/sys/bus/pci/devices/$NVIDIA_AUDIO/driver" 2>/dev/null)
        driver=${driver##*/}
        echo "  Driver in use: ${driver:-None}"
    else
        echo "  Not found"
    fi
}

case "$1" in
    bind)
        bind_gpu
        ;;
    unbind)
        unbind_gpu
        ;;
    status)
        status
        ;;
    *)
        echo "Usage: $0 {bind|unbind|status}"
        exit 1
        ;;
esac

exit 0