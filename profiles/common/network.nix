{
  systemd.services.NetworkManager-wait-online.enable = false;
  networking.networkmanager.enable = true;
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ ];
    allowedUDPPorts = [
      68
      546
    ];
  };
}
