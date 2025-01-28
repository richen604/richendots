{ pkgs, ... }:

let
  prime-run = pkgs.writeShellScriptBin "prime-run" ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    export DRI_PRIME=1
    export GBM_BACKEND=nvidia-drm
    export __GLX_PRIME_RENDER_OFFLOAD=1
    export LIBVA_DRIVER_NAME=nvidia
    export WLR_NO_HARDWARE_CURSORS=1
    exec "$@"
  '';
in
{
  environment.systemPackages = with pkgs; [
    # Add prime-run script as package
    prime-run
    # -------------------- Virtualization & VFIO --------------------
    qemu
    virt-manager # Virtual machine manager
    virt-viewer # Virtual machine viewer
    libvirt # Virtualization API
    spice-gtk # Remote display
    spice-protocol # Spice protocol
    spice-vdagent # Spice vdagent
    win-virtio # Windows virtio drivers
    win-spice # Windows spice drivers
    OVMF # UEFI firmware
    OVMFFull # UEFI firmware (with extra features)
    looking-glass-client # VFIO display
    freerdp3 # RDP client

    udisks # Storage device daemon
    udiskie # Automounter
    ntfs3g # NTFS filesystem support
    cpuset # CPU management
    kmod # Kernel module management
    inotify-tools # File change notification
  ];
}
