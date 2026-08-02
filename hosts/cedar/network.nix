{
  networking.networkmanager.enable = true;
  networking.interfaces.wlp3s0.wakeOnLan.enable = true;

  # Each address transition regenerates resolv.conf and restarts nscd.
  systemd.services.nscd.startLimitBurst = 20;
}
