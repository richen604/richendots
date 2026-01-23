{
  config,
  pkgs,
  ...
}:

# todo: fern vfio: make this module more generic, extendable, move to common
{
  system.activationScripts = {
    postActivation = ''
      # Create directories first
      mkdir -p /home/richen/.local/bin
      # Copy VFIO scripts and set permissions
      cp -f ${./scripts/vfio.sh} /home/richen/.local/bin/vfio
      cp -f ${./scripts/lg.sh} /home/richen/.local/bin/lg
      cp -f ${./scripts/start-vfio.sh} /home/richen/.local/bin/start-vfio
      cp -f ${./scripts/stop-vfio.sh} /home/richen/.local/bin/stop-vfio
      cp -f ${./scripts/vm.sh} /home/richen/.local/bin/vm
      cp -f ${./scripts/rdp.sh} /home/richen/.local/bin/rdp

      chown richen:users /home/richen/.local/bin/vfio
      chown richen:users /home/richen/.local/bin/lg
      chown richen:users /home/richen/.local/bin/start-vfio
      chown richen:users /home/richen/.local/bin/stop-vfio
      chown richen:users /home/richen/.local/bin/vm
      chown richen:users /home/richen/.local/bin/rdp
      chmod +x /home/richen/.local/bin/vfio
      chmod +x /home/richen/.local/bin/lg
      chmod +x /home/richen/.local/bin/start-vfio
      chmod +x /home/richen/.local/bin/stop-vfio
      chmod +x /home/richen/.local/bin/vm
      chmod +x /home/richen/.local/bin/rdp

      # Create a new directory for environment variables
      mkdir -p /etc/profile.d

      # Add scripts directory to system-wide PATH via profile.d
      echo 'export PATH="/home/richen/.local/bin:$PATH"' > /etc/profile.d/vfio-scripts.sh
      chmod +x /etc/profile.d/vfio-scripts.sh
    '';
  };

  services = {
    spice-vdagentd.enable = true;
    spice-webdavd.enable = true;
    udev.extraRules = ''
      SUBSYSTEM=="kvmfr", OWNER="richen", GROUP="kvm", MODE="0660"
    '';
  };

  networking = {
    interfaces.br0 = {
      useDHCP = true;
    };
    bridges.br0 = {
      interfaces = [ "enp7s0" ];
    };
    firewall = {
      allowedUDPPorts = [
        53
        67
      ];
      checkReversePath = false;
    };
    networkmanager.unmanaged = [
      "br0"
      "enp7s0"
    ];
  };

  users.users.richen = {
    extraGroups = pkgs.lib.mkAfter [
      "wheel"
      "networkmanager"
      "video"
      "libvirtd"
      "kvm"
      "qemu-libvirtd"
    ];
  };

  security = {
    polkit = {
      enable = true;
    };
    sudo.extraRules = [
      {
        groups = [ "wheel" ];
        commands = [
          {
            command = "/home/richen/.local/bin/vfio";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/home/richen/.local/bin/rdp";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/home/richen/.local/bin/vm";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/home/richen/.local/bin/lg";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };

  # VFIO-related configurations
  programs.virt-manager.enable = true;
  systemd.tmpfiles.rules = [
    "d /dev/hugepages 1770 root kvm -"
    "d /dev/shm 1777 root root -"
    "f /dev/shm/looking-glass 0660 richen kvm -"
  ];
  fileSystems."/dev/hugepages" = {
    device = "hugetlbfs";
    fsType = "hugetlbfs";
    options = [
      "mode=01770"
      "gid=kvm"
    ];
  };

  boot = {
    kernelParams = [
      # Memory Management
      "default_hugepagesz=2M" # Set default huge page size to 2MB
      "hugepagesz=2M" # Configure huge page size as 2MB
      "transparent_hugepage=never" # Disable transparent huge pages

      # Boot Optimization
      "fastboot" # Fast boot
      "quiet" # Reduce boot verbosity
      "rd.timeout=0" # Reduce initrd timeout
      "rd.systemd.show_status=false" # Hide systemd status during boot

      # RCU Stall Prevention
      "rcu_nocbs=all" # Move RCU callbacks off all CPUs
      "rcu_boost=1" # Enable RCU priority boosting
      "rcu_expedited=1" # Use expedited RCU grace periods
      "rcutree.rcu_idle_gp_delay=1" # Reduce RCU idle delay

      # Performance & Security
      # "mitigations=off" # Disable CPU vulnerabilities mitigations (security trade-off)
      # "nowatchdog" # Disable watchdog timer
      # "nmi_watchdog=0" # Disable NMI watchdog
      "radeon.modeset=0"

      # IOMMU & VFIO
      "intel_iommu=on" # Enable Intel IOMMU
      "iommu=pt" # Enable IOMMU pass-through
      "vfio-pci.ids=10de:2782,10de:22bc" # Specify VFIO PCI device IDs

      # KVM Settings
      "kvm.ignore_msrs=1" # Ignore unhandled Model Specific Registers
      "kvm.report_ignored_msrs=0" # Don't report ignored MSRs

      # ACPI & Power Management
      "acpi_osi=Linux" # Set ACPI OS interface to Linux
    ];
    kernelModules = [
      "vfio_pci"
      "vfio"
      "vfio_iommu_type1"
      "kvmfr"
      "kvm-intel"
      "kvm"
      "amdgpu"
    ];
    initrd.kernelModules = [
      "amdgpu"
      "vfio_pci"
      "vfio"
      "vfio_iommu_type1"
    ];
    extraModulePackages = with config.boot.kernelPackages; [
      kvmfr
    ];
    blacklistedKernelModules = [
      "nouveau"
      "nvidia"
      "nvidia_drm"
      "nvidia_modeset"
      "nvidia_uvm"
    ];
    extraModprobeConfig = ''
      options kvmfr static_size_mb=64
      blacklist nouveau
      options nouveau modeset=0
    '';
  };

  virtualisation = {

    libvirtd = {
      enable = true;
      hooks = {
        qemu = {
          # TODO: figure out the prepare script
          # "prepare" = ./modules/vfio/start.sh;
          # "release" = ./modules/vfio/stop.sh;
        };
      };
      qemu = {
        swtpm.enable = true;
        runAsRoot = true;
        package = pkgs.qemu_kvm;
        verbatimConfig = ''
          user = "richen"
          group = "kvm"
          cgroup_device_acl = [
            "/dev/null", "/dev/full", "/dev/zero",
            "/dev/random", "/dev/urandom",
            "/dev/ptmx", "/dev/kvm", "/dev/kqemu",
            "/dev/rtc","/dev/hpet", "/dev/sev",
            "/dev/kvmfr0",
            "/dev/vfio/vfio"
          ]
          hugetlbfs_mount = "/dev/hugepages"
          bridge_helper = "/run/wrappers/bin/qemu-bridge-helper"

          # Memory management settings for strict hugepage usage
          memory_backing_dir = "/dev/hugepages"
          cgroup_controllers = [ "memory" ]
        '';
      };
    };
    spiceUSBRedirection.enable = true;
  };

  users.groups.libvirtd.members = [ "richen" ];
  users.groups.kvm.members = [ "richen" ];

  systemd.services.define-win11-vm = {
    description = "Define Windows 11 VM";
    after = [ "libvirtd.service" ];
    requires = [ "libvirtd.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "root";
    };

    script = ''
      # Ensure NVRAM directory exists with proper permissions
      mkdir -p /var/lib/libvirt/qemu/nvram
      chown -R richen:kvm /var/lib/libvirt/qemu/nvram
      chmod 775 /var/lib/libvirt/qemu/nvram

      # Create symlink directory for OVMF files
      mkdir -p /var/libvirt/nix-ovmf
      rm -rf /var/libvirt/nix-ovmf/OVMF_CODE.fd
      rm -rf /var/libvirt/nix-ovmf/OVMF_VARS.fd
      ln -sf ${pkgs.OVMF.fd}/FV/OVMF_CODE.fd /var/libvirt/nix-ovmf/OVMF_CODE.fd
      ln -sf ${pkgs.OVMF.fd}/FV/OVMF_VARS.fd /var/libvirt/nix-ovmf/OVMF_VARS.fd
      chown -R richen:kvm /var/libvirt/nix-ovmf
      chmod -R 775 /var/libvirt/nix-ovmf

      # Copy OVMF NVRAM template if it doesn't exist
      rm -rf /var/lib/libvirt/qemu/nvram/win11_VARS.fd
      cp ${pkgs.OVMF.fd}/FV/OVMF_VARS.fd /var/lib/libvirt/qemu/nvram/win11_VARS.fd
      chown richen:kvm /var/lib/libvirt/qemu/nvram/win11_VARS.fd
      chmod 660 /var/lib/libvirt/qemu/nvram/win11_VARS.fd

      # setup win11.xml
      cp ${./scripts/win11.xml} /var/lib/libvirt/images/win11.xml
      chown richen:kvm /var/lib/libvirt/images/win11.xml

      ${pkgs.libvirt}/bin/virsh undefine win11 --nvram || true
      ${pkgs.libvirt}/bin/virsh define /var/lib/libvirt/images/win11.xml
    '';
  };

  environment.systemPackages = with pkgs; [
    # -------------------- Virtualization & VFIO --------------------
    qemu
    virt-manager # Virtual machine manager
    virt-viewer # Virtual machine viewer
    libvirt # Virtualization API
    spice-gtk # Remote display
    spice-protocol # Spice protocol
    spice-vdagent # Spice vdagent
    virtio-win # Windows virtio drivers
    win-spice # Windows spice drivers
    looking-glass-client # VFIO display
    freerdp # RDP client

    ntfs3g # NTFS filesystem support
    cpuset # CPU management
    kmod # Kernel module management
    inotify-tools # File change notification
  ];
}
