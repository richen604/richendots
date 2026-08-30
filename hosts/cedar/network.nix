{
  # Each address transition regenerates resolv.conf and restarts nscd.
  systemd.services.nscd.startLimitBurst = 20;
}
