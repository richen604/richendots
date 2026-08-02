{ pkgs, ... }:
{
  programs.dconf.enable = true;
  services.dbus.enable = true;
  services.gvfs.enable = true;
  security.pam.services.swaylock = { };
  services.greetd.enable = true;
  systemd.services.greetd.stopIfChanged = false;
  programs.xwayland.enable = true;
  services.graphical-desktop.enable = true;
  services.speechd.enable = false;

  environment.systemPackages = [ pkgs.kdePackages.kdeconnect-kde ];

  networking.firewall.interfaces.tailscale0 = {
    allowedTCPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
    ];
    allowedUDPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
    ];
  };

  systemd.user.services.kdeconnect-indicator = {
    description = "KDE Connect indicator";
    wantedBy = [ "mango-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.kdePackages.kdeconnect-kde}/bin/kdeconnect-indicator";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };
}
