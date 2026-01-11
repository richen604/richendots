{
  # Minimal hardware configuration for checks
  fileSystems."/" = {
    device = "/dev/null";
    fsType = "ext4";
  };
  nixpkgs.hostPlatform.system = "x86_64-linux";
}
