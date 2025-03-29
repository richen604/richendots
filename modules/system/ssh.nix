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
      "REMOVED_PUBLIC_KEY"
    ];

    networking.firewall.allowedTCPPorts = [ 22 ];
  };
}
