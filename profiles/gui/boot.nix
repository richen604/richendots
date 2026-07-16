{
  boot = {
    loader.grub.timeoutStyle = "hidden";
    loader.timeout = 0;
    loader.grub.splashImage = null;
    consoleLogLevel = 3;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "udev.log_priority=3"
      "systemd.show_status=auto"
      "8250.nr_uarts=0"
    ];
  };
}
