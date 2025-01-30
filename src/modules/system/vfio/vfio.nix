{
  config,
  userConfig,
  pkgs,
  ...
}:
let
  inherit (userConfig) username;
in
{

  imports = [
    ./packages.nix
  ];

  system.activationScripts = {
    postActivation = ''
      # Create directories first
      mkdir -p /home/${username}/.local/bin
      # Copy VFIO scripts and set permissions
      cp -f ${./scripts/vfio.sh} /home/${username}/.local/bin/vfio
      cp -f ${./scripts/lg.sh} /home/${username}/.local/bin/lg
      cp -f ${./scripts/start-vfio.sh} /home/${username}/.local/bin/start-vfio
      cp -f ${./scripts/stop-vfio.sh} /home/${username}/.local/bin/stop-vfio
      cp -f ${./scripts/vm.sh} /home/${username}/.local/bin/vm
      cp -f ${./scripts/rdp.sh} /home/${username}/.local/bin/rdp

      chown ${username}:users /home/${username}/.local/bin/vfio
      chown ${username}:users /home/${username}/.local/bin/lg
      chown ${username}:users /home/${username}/.local/bin/start-vfio
      chown ${username}:users /home/${username}/.local/bin/stop-vfio
      chown ${username}:users /home/${username}/.local/bin/vm
      chown ${username}:users /home/${username}/.local/bin/rdp
      chmod +x /home/${username}/.local/bin/vfio
      chmod +x /home/${username}/.local/bin/lg
      chmod +x /home/${username}/.local/bin/start-vfio
      chmod +x /home/${username}/.local/bin/stop-vfio
      chmod +x /home/${username}/.local/bin/vm
      chmod +x /home/${username}/.local/bin/rdp

      # Create a new directory for environment variables
      mkdir -p /etc/profile.d

      # Add scripts directory to system-wide PATH via profile.d
      echo 'export PATH="/home/${username}/.local/bin:$PATH"' > /etc/profile.d/vfio-scripts.sh
      chmod +x /etc/profile.d/vfio-scripts.sh
    '';
  };

  services = {
    spice-vdagentd.enable = true;
    spice-webdavd.enable = true;
    udev.extraRules = ''
      SUBSYSTEM=="kvmfr", OWNER="${username}", GROUP="kvm", MODE="0660"
      ${builtins.readFile ./scripts/99-vendor-reset.rules}
    '';
  };

  networking = {
    interfaces.br0 = {
      useDHCP = true;
    };
    bridges.br0 = {
      interfaces = [ "enp7s0" ];
      rstp = true;
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

  users.users.${username} = {
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
            command = "/home/${username}/.local/bin/vfio";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/home/${username}/.local/bin/rdp";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/home/${username}/.local/bin/vm";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/home/${username}/.local/bin/lg";
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
    "f /dev/shm/looking-glass 0660 ${username} kvm -"
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
      "mem_sleep_default=deep" # Set default sleep mode to deep sleep

      # Boot Optimization
      "fastboot" # Fast boot
      "quiet" # Reduce boot verbosity
      "rd.timeout=0" # Reduce initrd timeout
      "rd.systemd.show_status=false" # Hide systemd status during boot

      # Performance & Security
      "mitigations=off" # Disable CPU vulnerabilities mitigations (security trade-off)
      "nowatchdog" # Disable watchdog timer
      "nmi_watchdog=0" # Disable NMI watchdog
      "split_lock_detect=off" # Disable split lock detection
      "pcie_aspm=off" # Disable PCIe Active State Power Management
      "amdgpu.dc=1"
      "amdgpu.powerplay=1"
      "amdgpu.ppfeaturemask=0xffffffff"
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
      "acpi=force" # Force ACPI
      "resume_offset=0" # Set resume offset to 0
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
        ovmf = {
          enable = true;
          packages = [
            (pkgs.OVMFFull.override {
              secureBoot = true;
              tpmSupport = true;
            }).fd
          ];
        };
        swtpm.enable = true;
        runAsRoot = true;
        package = pkgs.qemu_kvm;
        verbatimConfig = ''
          user = "${username}"
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
        '';
      };
    };
    spiceUSBRedirection.enable = true;
  };

  users.groups.libvirtd.members = [ "${username}" ];
  users.groups.kvm.members = [ "${username}" ];

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
      mkdir -p ~/.config/libvirt/qemu/nvram
      chown -R ${username}:kvm ~/.config/libvirt/qemu/nvram
      chmod 775 ~/.config/libvirt/qemu/nvram

      # Copy OVMF NVRAM template if it doesn't exist
      if [ ! -f ~/.config/libvirt/qemu/nvram/win11_VARS.fd ]; then
        cp ${pkgs.OVMFFull.fd}/FV/OVMF_VARS.fd ~/.config/libvirt/qemu/nvram/win11_VARS.fd
        chown ${username}:kvm ~/.config/libvirt/qemu/nvram/win11_VARS.fd
        chmod 660 ~/.config/libvirt/qemu/nvram/win11_VARS.fd
      fi

      # Check if VM already exists
      if ! ${pkgs.libvirt}/bin/virsh list --all --name | grep -q "^win11$"; then
        ${pkgs.libvirt}/bin/virsh define ${./scripts/win11.xml}
      fi
    '';
  };
}
