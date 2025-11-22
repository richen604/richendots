{
  # Minimal hardware configuration for checks
  fileSystems."/" = {
    device = "/dev/null";
    fsType = "ext4";
  };
  boot.loader.grub.device = "/dev/null";
  nixpkgs.hostPlatform.system = "x86_64-linux";
}
