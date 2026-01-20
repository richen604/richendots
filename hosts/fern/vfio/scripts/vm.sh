#!/usr/bin/env bash

# Function to check if Win11 VM is running
check_win11_vm() {
    sudo virsh list --all | grep -q "win11.*running"
}

# Function to display VM status and available commands
show_status() {
    echo "Windows 11 VM Status:"
    if check_win11_vm; then
        echo "  Status: Running"
    else
        echo "  Status: Stopped"
    fi
    echo
    echo "Available commands:"
    echo "  vm         - Show this status"
    echo "  vm start   - Start the VM"
    echo "  vm stop    - Stop the VM"
}

# Function to start Win11 VM
start_win11_vm() {
    if check_win11_vm; then
        echo "VM is already running"
        return 1
    fi

    echo "Starting Windows 11 VM..."
    sudo start-vfio
    sudo virsh start win11

    # Set up trap to wait for VM shutdown using inotifywait with proper cleanup
    nohup bash -c '
        # Create a unique PID file for this monitor instance
        MONITOR_PID_FILE="/tmp/vm_monitor_$$.pid"
        echo $$ > "$MONITOR_PID_FILE"
        
        # Cleanup function
        cleanup() {
            rm -f "$MONITOR_PID_FILE"
            exit 0
        }
        
        # Set trap for cleanup
        trap cleanup EXIT
        
        echo "$(date): Waiting for VM shutdown" >> /tmp/vm_shutdown.log
        if inotifywait -e delete /var/run/libvirt/qemu/win11.pid; then
            echo "$(date): VM shutdown detected" >> /tmp/vm_shutdown.log
            sudo stop-vfio
            echo "$(date): VFIO stopped" >> /tmp/vm_shutdown.log
        else
            echo "$(date): inotifywait failed" >> /tmp/vm_shutdown.log
        fi
    ' >/dev/null 2>&1 &

    # Store the monitor process PID
    MONITOR_PID=$!
    echo "Background monitoring process started with PID $MONITOR_PID"
}

# Function to stop Win11 VM
stop_win11_vm() {
    if ! check_win11_vm; then
        echo "VM is not running"
        return 1
    fi

    echo "Stopping Windows 11 VM..."
    sudo virsh shutdown win11
    sudo stop-vfio

    # Cleanup any existing monitor processes
    for pid_file in /tmp/vm_monitor_*.pid; do
        if [ -f "$pid_file" ]; then
            pid=$(cat "$pid_file")
            kill $pid 2>/dev/null || true
            rm -f "$pid_file"
        fi
    done
}

# Main script command handling
case "${1:-status}" in
start)
    start_win11_vm
    ;;
stop)
    stop_win11_vm
    ;;
status | "")
    show_status
    ;;
*)
    echo "Unknown command: $1"
    echo "Usage: $0 [start|stop|status]"
    exit 1
    ;;
esac
