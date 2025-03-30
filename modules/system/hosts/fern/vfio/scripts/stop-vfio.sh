#!/run/current-system/sw/bin/bash
# https://rokups.github.io/#!pages/gaming-vm-performance.md


TOTAL_CORES='0-19'
TOTAL_CORES_MASK=FFFFF  # bitmask for all 20 threads
HOST_CORES='12-19'      # 2 P-cores (threads 12-15) + 4 E-cores (threads 16-19)
HOST_CORES_MASK=FF000   # bitmask 0b11111111000000000000
VIRT_CORES='0-11'       # 6 P-cores (threads 0-11)
VIRT_CORES_MASK=00FFF   # bitmask 0b00000000111111111111

unpin_cores() {
	# Reset all tasks to use all cores
	for pid in $(ps -eo pid --no-headers); do
		taskset -pc $TOTAL_CORES $pid > /dev/null 2>&1
	done
}

# Reset CPU affinity for systemd slices
systemctl set-property --runtime -- user.slice AllowedCPUs=$TOTAL_CORES
systemctl set-property --runtime -- system.slice AllowedCPUs=$TOTAL_CORES
systemctl set-property --runtime -- init.scope AllowedCPUs=$TOTAL_CORES

# All VMs offline
sysctl vm.stat_interval=1
sysctl -w kernel.watchdog=1
unpin_cores

# Reset writeback workqueue to use all cores
echo $TOTAL_CORES_MASK > /sys/bus/workqueue/devices/writeback/cpumask

# Hugepages deallocation
echo 0 | tee /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages
echo 0 | tee /proc/sys/vm/nr_hugepages

echo always | tee /sys/kernel/mm/transparent_hugepage/enabled
echo powersave | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

echo >&2 "VMs Unpinned"

# TODO: Implement NVIDIA driver reattachment and VFIO cleanup for NixOS
# This part needs to be adapted to NixOS-specific commands and paths
