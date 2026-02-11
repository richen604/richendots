{
  nixosConfiguration,
  ...
}:
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
            # todo: dev mode with editable shared folders
            # sharedDirectories = {
            #   flake = {
            #     source = "/home/richen/newdev/richendots";
            #     target = "/mnt/richendots";
            #   };
            # };
            memorySize = 14096;
            cores = 4;
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
          services.xserver = {
            videoDrivers = [
              "virtio"
            ];
          };
        };

        environment.variables = {
          WLR_NO_HARDWARE_CURSORS = "1";
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
      }
    )
  ];
}
