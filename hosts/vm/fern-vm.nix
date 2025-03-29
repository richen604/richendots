{ inputs, nixosConfiguration, ... }:
nixosConfiguration.extendModules {
  modules = [
    (
      {
        config,
        pkgs,
        lib,
        ...
      }:
      {
        # Rest of VM configuration
        virtualisation.vmVariant = {
          virtualisation = {
            memorySize = 4096;
            cores = 2;
            diskSize = 10240;
            qemu = {
              options = [
                "-device virtio-vga-gl"
                "-display gtk,gl=on,grab-on-hover=on"
                "-usb -device usb-tablet"
                "-cpu host"
                "-enable-kvm"
                "-machine q35"
                "-device intel-iommu"
                "-device ich9-intel-hda"
                "-device hda-output"
                "-vga none"
              ];
            };
          };
          #! you can set this to skip login for sddm
          # services.displayManager.autoLogin = {
          #   enable = true;
          #   user = "hydenix";
          # };
          services.xserver = {
            videoDrivers = [
              "virtio"
            ];
          };

          # Disable OBS module in the VM
          home-manager.users.richen.modules.obs.enable = inputs.nixpkgs.lib.mkForce false;
          modules = {
            wol = {
              enable = lib.mkForce false;
            };
            sunshine.enable = lib.mkForce false;
            autologin.enable = lib.mkForce false;
            vfio.enable = lib.mkForce false;
            drivers.enable = lib.mkForce false;
            linux-cachyos.enable = lib.mkForce false;
            plex.enable = lib.mkForce false;
            boot.enable = lib.mkForce false;
            ssh.enable = lib.mkForce true;
            steam.enable = lib.mkForce false;
            dev.enable = lib.mkForce true;
          };
        };

        virtualisation.libvirtd.enable = true;
        environment.systemPackages = with pkgs; [
          open-vm-tools
          spice-gtk
          spice-vdagent
          spice
        ];
        services.qemuGuest.enable = true;
        services.spice-vdagentd = {
          enable = true;
        };
        hardware.graphics.enable = true;

        # Enable verbose logging for home-manager
        # home-manager.verbose = true;
      }
    )
  ];
}
