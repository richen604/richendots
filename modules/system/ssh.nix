{ config, lib, ... }:

let
  cfg = config.modules.ssh;
in
{
  options.modules.ssh = {
    enable = lib.mkEnableOption "ssh";
  };

  config = lib.mkIf cfg.enable {
    services = {
      openssh = {
        enable = true;
        settings = {
          PasswordAuthentication = false;
          PermitRootLogin = "no";
          MaxAuthTries = 3;
        };
      };
    };

    users.users."richen".openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICLEXtZYHT5O3cWgfF2FHEjXHa/FPGGqOpBAAe7LeDvW"
    ];

    networking.firewall.allowedTCPPorts = [ 22 ];
  };
}
