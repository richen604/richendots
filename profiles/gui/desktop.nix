{
  programs.dconf.enable = true;
  services.dbus.enable = true;
  services.gvfs.enable = true;
  security.pam.services.swaylock = { };
  services.greetd.enable = true;
  programs.xwayland.enable = true;
  services.graphical-desktop.enable = true;
  services.speechd.enable = false;
}
