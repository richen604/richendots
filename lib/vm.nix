{
  pkgs,
  ...
}:
{
  virtualisation = {
    libvirtd.enable = true;

    vmVariant = {
      virtualisation = {
        memorySize = 14096;
        cores = 4;
        diskSize = 10240;

        qemu.options = [
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

      services.xserver.videoDrivers = [ "virtio" ];
    };
  };

  environment = {
    variables.WLR_NO_HARDWARE_CURSORS = "1";

    systemPackages = with pkgs; [
      open-vm-tools
      spice-gtk
      spice-vdagent
      spice
    ];
  };

  services = {
    qemuGuest.enable = true;
    spice-vdagentd.enable = true;
  };

  hardware.graphics.enable = true;
}
